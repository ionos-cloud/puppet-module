require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:snapshot).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    PuppetX::IonoscloudX::Helper.ionoscloud_config
    super(*args)
    @property_flush = {}
  end

  def self.instances
    PuppetX::IonoscloudX::Helper.ionoscloud_config
    snapshots = []
    Ionoscloud::SnapshotApi.new.snapshots_get(depth: 1).items.each do |snapshot|
      snapshots << new(instance_to_hash(snapshot))
    end
    snapshots.flatten
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
      size: instance.properties.size,
      location: instance.properties.location,
      cpu_hot_plug: instance.properties.cpu_hot_plug,
      cpu_hot_unplug: instance.properties.cpu_hot_unplug,
      ram_hot_plug: instance.properties.ram_hot_plug,
      ram_hot_unplug: instance.properties.ram_hot_unplug,
      nic_hot_plug: instance.properties.nic_hot_plug,
      nic_hot_unplug: instance.properties.nic_hot_unplug,
      disc_virtio_hot_plug: instance.properties.disc_virtio_hot_plug,
      disc_virtio_hot_unplug: instance.properties.disc_virtio_hot_unplug,
      disc_scsi_hot_plug: instance.properties.disc_scsi_hot_plug,
      disc_scsi_hot_unplug: instance.properties.disc_scsi_hot_unplug,
      licence_type: instance.properties.licence_type,
      sec_auth_protection: instance.properties.sec_auth_protection,
      ensure: :present,
    }
  end

  def restore=(_value)
    # restore setter is only invoked on restore => true
    datacenter_id = get_datacenter_id(resource[:datacenter])
    volume_id = get_volume_id(datacenter_id, resource[:volume])

    _, _, headers = Ionoscloud::VolumeApi.new.datacenters_volumes_restore_snapshot_post_with_http_info(
      datacenter_id, volume_id, { snapshot_id: @property_hash[:id] }
    )
    Puppet.info("Restoring snapshot '#{name}' onto volume '#{resource[:volume]}'...")
    PuppetX::IonoscloudX::Helper.wait_request(headers)
  end

  def description=(value)
    @property_flush[:description] = value
  end

  def cpu_hot_plug=(value)
    @property_flush[:cpu_hot_plug] = value
  end

  def cpu_hot_unplug=(value)
    @property_flush[:cpu_hot_unplug] = value
  end

  def ram_hot_plug=(value)
    @property_flush[:ram_hot_plug] = value
  end

  def ram_hot_unplug=(value)
    @property_flush[:ram_hot_unplug] = value
  end

  def nic_hot_plug=(value)
    @property_flush[:nic_hot_plug] = value
  end

  def nic_hot_unplug=(value)
    @property_flush[:nic_hot_unplug] = value
  end

  def disc_virtio_hot_plug=(value)
    @property_flush[:disc_virtio_hot_plug] = value
  end

  def disc_virtio_hot_unplug=(value)
    @property_flush[:disc_virtio_hot_unplug] = value
  end

  def disc_scsi_hot_plug=(value)
    @property_flush[:disc_scsi_hot_plug] = value
  end

  def disc_scsi_hot_unplug=(value)
    @property_flush[:disc_scsi_hot_unplug] = value
  end

  def sec_auth_protection=(value)
    @property_flush[:sec_auth_protection] = value
  end

  def licence_type=(value)
    @property_flush[:licence_type] = value
  end

  def exists?
    Puppet.info("Checking if snapshot '#{name}' exists.")
    @property_hash[:ensure] == :present
  end

  def create
    datacenter_id = get_datacenter_id(resource[:datacenter])
    volume_id = get_volume_id(datacenter_id, resource[:volume])

    snapshot, _, headers = Ionoscloud::VolumeApi.new.datacenters_volumes_create_snapshot_post_with_http_info(
      datacenter_id,
      volume_id,
      {
        name: resource[:name],
        description: resource[:description],
        sec_auth_protection: resource[:sec_auth_protection],
        licence_type: resource[:licence_type],
      },
    )
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    Puppet.info("Created new snapshot '#{name}'.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = snapshot.id
    @property_hash[:datacenter] = datacenter_id
    @property_hash[:volume] = volume_id
  end

  def flush
    changeable_properties = [
      :description, :cpu_hot_plug, :cpu_hot_unplug, :ram_hot_plug, :ram_hot_unplug,
      :nic_hot_plug, :nic_hot_unplug, :disc_virtio_hot_plug, :disc_virtio_hot_unplug,
      :disc_scsi_hot_plug, :disc_scsi_hot_unplug, :licence_type, :licence_type, :sec_auth_protection,
    ]
    changes = Hash[ *changeable_properties.map { |property| [ property, @property_flush[property] ] }.flatten ].delete_if { |_k, v| v.nil? }

    return if changes.empty?

    Puppet.info("Updating snapshot '#{name}', #{changes.keys}.")
    changes = Ionoscloud::SnapshotProperties.new(**changes)

    _, _, headers = Ionoscloud::SnapshotApi.new.snapshots_patch_with_http_info(@property_hash[:id], changes)

    PuppetX::IonoscloudX::Helper.wait_request(headers)

    changeable_properties.each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
  end

  def destroy
    Puppet.info("Deleting snapshot '#{name}'...")
    _, _, headers = Ionoscloud::SnapshotApi.new.snapshots_delete_with_http_info(@property_hash[:id])
    PuppetX::IonoscloudX::Helper.wait_request(headers)
    @property_hash[:ensure] = :absent
  end

  private

  def get_datacenter_id(datacenter_id_or_name)
    return datacenter_id_or_name if PuppetX::IonoscloudX::Helper.validate_uuid_format(datacenter_id_or_name)
    PuppetX::IonoscloudX::Helper.resolve_datacenter_id(nil, datacenter_id_or_name)
  end

  def get_volume_id(datacenter_id, volume_id_or_name)
    return volume_id_or_name if PuppetX::IonoscloudX::Helper.validate_uuid_format(volume_id_or_name)
    PuppetX::IonoscloudX::Helper.volume_from_name(volume_id_or_name, datacenter_id).id
  end
end
