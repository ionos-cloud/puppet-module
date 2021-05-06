require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:share).provide(:v1) do
  # confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    PuppetX::Profitbricks::Helper::profitbricks_config
    super(*args)
    @property_flush = {}
  end

  def self.instances
    PuppetX::Profitbricks::Helper::profitbricks_config

    Ionoscloud::UserManagementApi.new.um_groups_get(depth: 2).items.map do |group|
      shares = []
      resources = Hash.new
      group.entities.resources.items.map do |resource|
        resources[resource.id] = resource.type
      end
      unless resources.empty?
        Ionoscloud::UserManagementApi.new.um_groups_shares_get(group.id, depth: 1).items.map do |share|
          shares << new(instance_to_hash(share, group, resources))
        end
      end
      shares
    end.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        if resource[:group_id] == prov.group_id || resource[:group_name] == prov.group_name
          resource.provider = prov
        end
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

    group_id = PuppetX::Profitbricks::Helper::resolve_group_id(resource[:group_id], resource[:group_name])

    share, _, headers  = Ionoscloud::UserManagementApi.new.um_groups_shares_post_with_http_info(
      group_id,
      resource[:name],
      share,
    )
    PuppetX::Profitbricks::Helper::wait_request(headers)

    Puppet.info("Added share #{share.id}.")
    @property_hash[:ensure] = :present
    @property_hash[:name] = share.id
    @property_hash[:group_id] = group_id
  end

  def flush
    unless @property_flush.empty?
      share = Ionoscloud::GroupShare.new(
        properties: Ionoscloud::GroupShareProperties.new(
          edit_privilege: (@property_flush[:edit_privilege].nil? ? @property_hash[:edit_privilege] : @property_flush[:edit_privilege]),
          share_privilege: (@property_flush[:share_privilege].nil? ? @property_hash[:share_privilege] : @property_flush[:share_privilege]),
        ),
      )

      share, _, headers  = Ionoscloud::UserManagementApi.new.um_groups_shares_put_with_http_info(
        PuppetX::Profitbricks::Helper::resolve_group_id(@property_hash[:group_id],  @property_hash[:group_name]),
        @property_hash[:name],
        share,
      )
      PuppetX::Profitbricks::Helper::wait_request(headers)

      @property_hash[:edit_privilege] = share.properties.edit_privilege
      @property_hash[:share_privilege] = share.properties.share_privilege
    end
  end

  def destroy
    group_id = PuppetX::Profitbricks::Helper::resolve_group_id(@property_hash[:group_id], @property_hash[:group_name])
    _, _, headers = Ionoscloud::UserManagementApi.new.um_groups_shares_delete_with_http_info(group_id, @property_hash[:name])
    PuppetX::Profitbricks::Helper::wait_request(headers)
    Puppet.info("Removing share #{@property_hash[:name]}.")
    @property_hash[:ensure] = :absent
  end
end
