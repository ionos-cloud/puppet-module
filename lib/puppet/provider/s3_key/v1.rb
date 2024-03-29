require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:s3_key).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def self.instances
    PuppetX::IonoscloudX::Helper.user_management_api.um_users_get(depth: 1).items.map { |user|
      s3_keys = []
      # Ignore user if email is not defined.
      unless user.properties.email.nil? || user.properties.email.empty?
        PuppetX::IonoscloudX::Helper.s3_keys_api.um_users_s3keys_get(user.id, depth: 1).items.each do |s3_key|
          s3_keys << new(instance_to_hash(s3_key, user))
        end
      end
      s3_keys
    }.flatten
  end

  def self.instance_to_hash(instance, user)
    {
      name: instance.id,
      user_id: user.id,
      user_email: user.properties.email,
      secret_key: instance.properties.secret_key,
      active: instance.properties.active,
    }
  end
end
