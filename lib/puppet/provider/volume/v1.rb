require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:volume).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    PuppetX::IonoscloudX::Helper.ionoscloud_config
    super(*args)
  end

  def self.instances
    PuppetX::IonoscloudX::Helper.ionoscloud_config
    Ionoscloud::DataCentersApi.new.datacenters_get(depth: 1).items.map { |datacenter|
      volumes = []
      # Ignore data center if name is not defined.
      unless datacenter.properties.name.nil? || datacenter.properties.name.empty?
        Ionoscloud::VolumesApi.new.datacenters_volumes_get(datacenter.id, depth: 1).items.each do |volume|
          volumes << new(instance_to_hash(volume, datacenter))
        end
      end
      volumes
    }.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      next unless (resource = resources[prov.name])
      if resource[:datacenter_id] == prov.datacenter_id || resource[:datacenter_name] == prov.datacenter_name
        resource.provider = prov
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
      user_data: instance.properties.user_data,
      licence_type: instance.properties.licence_type,
      backupunit_id: instance.properties.backupunit_id,
      pci_slot: instance.properties.pci_slot,
      device_number: instance.properties.device_number,
      availability_zone: instance.properties.availability_zone,
      cpu_hot_plug: instance.properties.cpu_hot_plug,
      ram_hot_plug: instance.properties.ram_hot_plug,
      nic_hot_plug: instance.properties.nic_hot_plug,
      nic_hot_unplug: instance.properties.nic_hot_unplug,
      disc_virtio_hot_plug: instance.properties.disc_virtio_hot_plug,
      disc_virtio_hot_unplug: instance.properties.disc_virtio_hot_unplug,
      ensure: :present,
    }
  end

  def exists?
    Puppet.info("Checking if volume #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def size=(value)
    PuppetX::IonoscloudX::Helper.update_volume(@property_hash[:datacenter_id], @property_hash[:id], @property_hash, { 'size' => value }, true)
    @property_hash[:size] = value
  end

  def create
    volume = PuppetX::IonoscloudX::Helper.volume_object_from_hash(resource)

    Puppet.info "Creating a new volume #{volume.to_hash}."

    datacenter_id = PuppetX::IonoscloudX::Helper.resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])

    volume, _, headers = Ionoscloud::VolumesApi.new.datacenters_volumes_post_with_http_info(datacenter_id, volume)
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    Puppet.info("Created a new volume named #{resource[:name]}.")
    @property_hash[:ensure] = :present
    @property_hash[:datacenter_id] = datacenter_id
    @property_hash[:id] = volume.id
    @property_hash[:size] = Integer(volume.properties.size)
  end

  def destroy
    _, _, headers = Ionoscloud::VolumesApi.new.datacenters_volumes_delete_with_http_info(@property_hash[:datacenter_id], @property_hash[:id])
    PuppetX::IonoscloudX::Helper.wait_request(headers)
    @property_hash[:ensure] = :absent
  end
end
