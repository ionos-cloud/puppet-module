require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:location).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    PuppetX::IonoscloudX::Helper.ionoscloud_config
    super(*args)
  end

  def self.instances
    PuppetX::IonoscloudX::Helper.ionoscloud_config

    locations = []
    Ionoscloud::LocationsApi.new.locations_get(depth: 1).items.each do |location|
      locations << new(instance_to_hash(location))
    end
    locations.flatten
  end

  def self.instance_to_hash(instance)
    {
      id: instance.id,
      name: instance.properties.name,
      features: instance.properties.features,
      image_aliases: instance.properties.image_aliases,
    }
  end
end
