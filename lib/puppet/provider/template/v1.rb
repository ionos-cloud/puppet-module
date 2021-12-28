require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:template).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    super(*args)
  end

  def self.instances
    templates = []
    PuppetX::IonoscloudX::Helper.templates_api.templates_get(depth: 1).items.each do |template|
      templates << new(instance_to_hash(template))
    end
    templates.flatten
  end

  def self.instance_to_hash(instance)
    {
      name: instance.properties.name,
      cores: instance.properties.cores,
      ram: instance.properties.ram,
      storage_size: instance.properties.storage_size,
    }
  end
end
