require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:volume).provide(:v1) do
  confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    PuppetX::Profitbricks::Helper::profitbricks_config()
    super(*args)
  end

  def self.instances
    Ionoscloud::DataCenterApi.new.datacenters_get(depth: 1).items.map do |datacenter|
      volumes = []
      # Ignore data center if name is not defined.
      unless datacenter.properties.name.nil? || datacenter.properties.name.empty?
        Ionoscloud::VolumeApi.new.datacenters_volumes_get(datacenter.id, depth: 1).items.each do |volume|
          volumes << new(instance_to_hash(volume, datacenter))
        end
      end
      volumes
    end.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        if resource[:datacenter_id] == prov.datacenter_id || resource[:datacenter_name] == prov.datacenter_name
          resource.provider = prov
        end
      end
    end
  end

  def self.instance_to_hash(instance, datacenter)
    {
      id: instance.id,
      datacenter_id: datacenter.id,
      datacenter_name: datacenter.properties.name,
      name: instance.properties.name,
      size: Integer(instance.properties.size),
      volume_type: instance.properties.type,
      bus: instance.properties.bus,
      image_id: instance.properties.image,
      licence_type: instance.properties.licence_type,
      availability_zone: instance.properties.availability_zone,
      ensure: :present,
    }
  end

  def exists?
    Puppet.info("Checking if volume #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def size=(value)
    PuppetX::Profitbricks::Helper::update_volume(@property_hash[:datacenter_id], @property_hash[:id], @property_hash, { 'size' => value }, true)
    @property_hash[:size] = value
  end

  def create
    # volume = PuppetX::Profitbricks::Helper::volume_object_from_hash(
    #   'name' => resource[:name].to_s,
    #   'availability_zone' => resource[:availability_zone].to_s,
    #   'image' => resource[:image_id].to_s,
    #   'image_alias' => resource[:image_alias].to_s,
    #   'bus' => resource[:bus].to_s,
    #   'type' => resource[:volume_type].to_s,
    #   'size' => resource[:size],
    #   'licence_type' => resource[:licence_type].to_s,
    #   'image_password' => resource[:image_password].to_s,
    #   'ssh_keys' => resource[:ssh_keys],
    # )

    volume = PuppetX::Profitbricks::Helper::volume_object_from_hash(resource)

    puts "Creating a new volume #{volume.to_hash}."

    datacenter_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])

    volume, _, headers = Ionoscloud::VolumeApi.new.datacenters_volumes_post_with_http_info(datacenter_id, volume)
    PuppetX::Profitbricks::Helper::wait_request(headers)

    Puppet.info("Created a new volume named #{resource[:name]}.")
    @property_hash[:ensure] = :present
    @property_hash[:datacenter_id] = datacenter_id
    @property_hash[:id] = volume.id
    @property_hash[:size] = Integer(volume.properties.size)
  end

  def destroy
    _, _, headers = Ionoscloud::VolumeApi.new.datacenters_volumes_delete_with_http_info(@property_hash[:datacenter_id], @property_hash[:id])
    PuppetX::Profitbricks::Helper::wait_request(headers)
    @property_hash[:ensure] = :absent
  end
end
