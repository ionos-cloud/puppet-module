require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:resource).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def self.instances
    resources = []

    PuppetX::IonoscloudX::Helper.user_management_api.um_resources_get(depth: 1).items.each do |resource|
      resources << new(instance_to_hash(resource))
    end
    resources.flatten
  end

  def self.instance_to_hash(instance)
    {
      id: instance.id,
      name: instance.properties.name,
      type: instance.type,
    }
  end
end
