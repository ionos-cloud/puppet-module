require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:share).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    super(*args)
    @property_flush = {}
  end

  def self.instances
    PuppetX::IonoscloudX::Helper.user_management_api.um_groups_get(depth: 2).items.map { |group|
      shares = []
      resources = {}
      group.entities.resources.items.map do |resource|
        resources[resource.id] = resource.type
      end
      unless resources.empty?
        PuppetX::IonoscloudX::Helper.user_management_api.um_groups_shares_get(group.id, depth: 1).items.map do |share|
          shares << new(instance_to_hash(share, group, resources))
        end
      end
      shares
    }.flatten
  end

  def self.prefetch(resources)
    resources.each_key do |key|
      resource = resources[key]
      next unless instances.count { |instance|
        instance.name == key &&
        (resource[:group_id] == instance.group_id || resource[:group_name] == instance.group_name)
      } > 1
      raise Puppet::Error, "Multiple #{resources[key].type} instances found for '#{key}'!"
    end
    instances.each do |prov|
      next unless (resource = resources[prov.name])
      if resource[:group_id] == prov.group_id || resource[:group_name] == prov.group_name
        resource.provider = prov
      end
    end
  end

  def self.instance_to_hash(share, group, resources)
    {
      name: share.id,
      type: resources[share.id],
      group_id: group.id,
      group_name: group.properties.name,
      edit_privilege: share.properties.edit_privilege,
      share_privilege: share.properties.share_privilege,
      ensure: :present,
    }
  end

  def edit_privilege=(value)
    @property_flush[:edit_privilege] = value
  end

  def share_privilege=(value)
    @property_flush[:share_privilege] = value
  end

  def exists?
    Puppet.info("Checking if share #{name} exists.")
    @property_hash[:ensure] == :present
  end

  def create
    share = Ionoscloud::GroupShare.new(
      properties: Ionoscloud::GroupShareProperties.new(
        edit_privilege: resource[:edit_privilege],
        share_privilege: resource[:share_privilege],
      ),
    )

    group_id = PuppetX::IonoscloudX::Helper.resolve_group_id(resource[:group_id], resource[:group_name])

    share, _, headers = PuppetX::IonoscloudX::Helper.user_management_api.um_groups_shares_post_with_http_info(
      group_id,
      resource[:name],
      share,
    )
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    Puppet.info("Added share #{share.id}.")
    @property_hash[:ensure] = :present
    @property_hash[:name] = share.id
    @property_hash[:group_id] = group_id
  end

  def flush
    return if @property_flush.empty?
    return if @property_flush.empty?

    share = Ionoscloud::GroupShare.new(
      properties: Ionoscloud::GroupShareProperties.new(
        edit_privilege: (@property_flush[:edit_privilege].nil? ? @property_hash[:edit_privilege] : @property_flush[:edit_privilege]),
        share_privilege: (@property_flush[:share_privilege].nil? ? @property_hash[:share_privilege] : @property_flush[:share_privilege]),
      ),
    )

    share, _, headers = PuppetX::IonoscloudX::Helper.user_management_api.um_groups_shares_put_with_http_info(
      PuppetX::IonoscloudX::Helper.resolve_group_id(@property_hash[:group_id], @property_hash[:group_name]),
      @property_hash[:name],
      share,
    )
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:edit_privilege] = share.properties.edit_privilege
    @property_hash[:share_privilege] = share.properties.share_privilege
    @property_flush = {}
  end

  def destroy
    group_id = PuppetX::IonoscloudX::Helper.resolve_group_id(@property_hash[:group_id], @property_hash[:group_name])
    _, _, headers = PuppetX::IonoscloudX::Helper.user_management_api.um_groups_shares_delete_with_http_info(group_id, @property_hash[:name])
    PuppetX::IonoscloudX::Helper.wait_request(headers)
    Puppet.info("Removing share #{@property_hash[:name]}.")
    @property_hash[:ensure] = :absent
  end
end
