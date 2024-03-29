require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:ipblock).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def self.instances
    ipblocks = []
    PuppetX::IonoscloudX::Helper.ip_blocks_api.ipblocks_get(depth: 1).items.each do |ipblock|
      ipblocks << new(instance_to_hash(ipblock))
    end
    ipblocks.flatten
  end

  def self.prefetch(resources)
    resources.each_key do |key|
      if instances.count { |instance| instance.name == key } > 1
        raise Puppet::Error, "Multiple #{resources[key].type} instances found for '#{key}'!"
      end
    end
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:name] == prov.name
      end
    end
  end

  def self.instance_to_hash(instance)
    {
      id: instance.id,
      created_by: instance.metadata.created_by,
      name: instance.properties.name,
      size: instance.properties.size,
      location: instance.properties.location,
      ips: instance.properties.ips,
      ip_consumers: instance.properties.ip_consumers,
      ensure: :present,
    }
  end

  def exists?
    Puppet.info("Checking if ipblock '#{name}' exists.")
    @property_hash[:ensure] == :present
  end

  def create
    ipblock = Ionoscloud::IpBlock.new(
      properties: Ionoscloud::IpBlockProperties.new(
        name: resource[:name],
        size: resource[:size],
        location: resource[:location],
      ),
    )

    ipblock, _, headers = PuppetX::IonoscloudX::Helper.ip_blocks_api.ipblocks_post_with_http_info(ipblock)
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    Puppet.info("Created new ipblock '#{name}'.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = ipblock.id
  end

  def destroy
    Puppet.info("Deleting ipblock '#{name}'...")
    _, _, headers = PuppetX::IonoscloudX::Helper.ip_blocks_api.ipblocks_delete_with_http_info(@property_hash[:id])
    PuppetX::IonoscloudX::Helper.wait_request(headers)
    @property_hash[:ensure] = :absent
  end
end
