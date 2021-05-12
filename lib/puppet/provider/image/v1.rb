require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:image).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    PuppetX::IonoscloudX::Helper::ionoscloud_config
    super(*args)
  end

  def self.instances
    PuppetX::IonoscloudX::Helper::ionoscloud_config

    images = []

    Ionoscloud::ImageApi.new.images_get(depth: 1).items.each do |image|
      images << new(instance_to_hash(image))
    end
    images.flatten
  end

  def self.instance_to_hash(instance)
    {
      id: instance.id,
      name: instance.properties.name,
      description: instance.properties.description,
      location: instance.properties.location,
      size: instance.properties.size,
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
      public: instance.properties.public,
      image_type: instance.properties.image_type,
      licence_type: instance.properties.licence_type,
      # image_aliases: instance.properties.image_aliases,
    }
  end
end
