require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:datacenter).provide(:v1) do
  confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    PuppetX::Profitbricks::Helper::profitbricks_config
    super(*args)
  end

  def self.instances
    PuppetX::Profitbricks::Helper::profitbricks_config
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
    config = {
      id: instance.id,
      name: instance.properties.name,
      description: instance.properties.description,
      location: instance.properties.location,
      ensure: :present,
    }
  end

  def description=(value)
    Puppet.info("Updating data center '#{resource[:name]}' description.")

    datacenter = PuppetX::Profitbricks::Helper::datacenter_from_name(name)
    changes = Ionoscloud::DatacenterProperties.new(
      description: value,
    )

    datacenter, _, headers = Ionoscloud::DataCenterApi.new.datacenters_patch_with_http_info(datacenter.id, changes)
    PuppetX::Profitbricks::Helper::wait_request(headers)
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
    PuppetX::Profitbricks::Helper::wait_request(headers)

    @property_hash[:ensure] = :present
  end

  def destroy
    Puppet.info("Deleting data center #{resource[:name]}.")

    datacenter = PuppetX::Profitbricks::Helper::datacenter_from_name(resource[:name])
    _, _, headers = Ionoscloud::DataCenterApi.new.datacenters_delete_with_http_info(datacenter.id)
    PuppetX::Profitbricks::Helper::wait_request(headers)

    @property_hash[:ensure] = :absent
  end
end
