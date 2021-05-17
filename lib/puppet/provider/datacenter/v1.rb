require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:datacenter).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    PuppetX::IonoscloudX::Helper.ionoscloud_config
    super(*args)
    @property_flush = {}
  end

  def self.instances
    PuppetX::IonoscloudX::Helper.ionoscloud_config
    datacenters = []
    Ionoscloud::DataCenterApi.new.datacenters_get(depth: 1).items.each do |dc|
      # Ignore data centers if name is not defined.
      datacenters << new(instance_to_hash(dc)) unless dc.properties.name.nil? || dc.properties.name.empty?
    end
    datacenters.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:name] == prov.name
      end
    end
  end

  def self.instance_to_hash(instance)
    {
      id: instance.id,
      name: instance.properties.name,
      description: instance.properties.description,
      location: instance.properties.location,
      version: instance.properties.version,
      sec_auth_protection: instance.properties.sec_auth_protection,
      features: instance.properties.features,
      ensure: :present,
    }
  end

  def sec_auth_protection=(value)
    @property_flush[:sec_auth_protection] = value
  end

  def description=(value)
    @property_flush[:description] = value
  end

  def exists?
    Puppet.info("Checking if data center #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def create
    Puppet.info("Creating a new data center named #{resource[:name]}.")

    datacenter = Ionoscloud::Datacenter.new(
      properties: Ionoscloud::DatacenterProperties.new(
        name: resource[:name],
        description: resource[:description],
        location: resource[:location],
      ),
    )
    datacenter, _, headers = Ionoscloud::DataCenterApi.new.datacenters_post_with_http_info(datacenter)
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:ensure] = :present
    @property_hash[:id] = datacenter.id
  end

  def flush
    changeable_properties = [:description, :sec_auth_protection]
    changes = Hash[ *changeable_properties.map { |property| [ property, @property_flush[property] ] }.flatten ].delete_if { |_k, v| v.nil? }

    return if changes.empty?

    changes = Ionoscloud::DatacenterProperties.new(**changes)

    _, _, headers = Ionoscloud::DataCenterApi.new.datacenters_patch_with_http_info(@property_hash[:id], changes)
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    changeable_properties.each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
  end

  def destroy
    Puppet.info("Deleting data center #{@property_hash[:name]}.")

    _, _, headers = Ionoscloud::DataCenterApi.new.datacenters_delete_with_http_info(@property_hash[:id])
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:ensure] = :absent
  end
end
