require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:profitbricks_group).provide(:v1) do
  confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    PuppetX::Profitbricks::Helper::profitbricks_config
    super(*args)
    @property_flush = {}
  end

  def self.instances
    PuppetX::Profitbricks::Helper::profitbricks_config

    groups = []
    Ionoscloud::UserManagementApi.new.um_groups_get(depth: 3).items.each do |group|
      groups << new(instance_to_hash(group))
    end
    groups.flatten
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
      create_data_center: instance.properties.create_data_center,
      create_snapshot: instance.properties.create_snapshot,
      reserve_ip: instance.properties.reserve_ip,
      access_activity_log: instance.properties.access_activity_log,
      s3_privilege: instance.properties.s3_privilege,
      create_backup_unit: instance.properties.create_backup_unit,
      members: instance.entities.users.items.map { |user| user.properties.email },
      ensure: :present,
    }
  end

  def create_data_center=(value)
    @property_flush[:create_data_center] = value
  end

  def create_snapshot=(value)
    @property_flush[:create_snapshot] = value
  end

  def reserve_ip=(value)
    @property_flush[:reserve_ip] = value
  end

  def access_activity_log=(value)
    @property_flush[:access_activity_log] = value
  end

  def s3_privilege=(value)
    @property_flush[:s3_privilege] = value
  end

  def create_backup_unit=(value)
    @property_flush[:create_backup_unit] = value
  end

  def members=(value)
    sync_members(@property_hash[:id], @property_hash[:members], value)
  end

  def exists?
    Puppet.info("Checking if profitbricks group #{name} exists.")
    @property_hash[:ensure] == :present
  end

  def create
    group = Ionoscloud::Group.new(
      properties: Ionoscloud::GroupProperties.new(
        name: resource[:name],
        create_data_center: resource[:create_data_center],
        create_snapshot: resource[:create_snapshot],
        reserve_ip: resource[:reserve_ip],
        access_activity_log: resource[:access_activity_log],
        s3_privilege: resource[:s3_privilege],
        create_backup_unit: resource[:create_backup_unit],
      ),
    )

    group, _, headers = Ionoscloud::UserManagementApi.new.um_groups_post_with_http_info(group)
    PuppetX::Profitbricks::Helper::wait_request(headers)

    Puppet.info("Created new profitbricks group #{name}.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = group.id
    @property_hash[:name] = group.properties.name
    @property_hash[:create_data_center] = group.properties.create_data_center
    @property_hash[:create_snapshot] = group.properties.create_snapshot
    @property_hash[:reserve_ip] = group.properties.reserve_ip
    @property_hash[:access_activity_log] = group.properties.access_activity_log
    @property_hash[:s3_privilege] = group.properties.s3_privilege
    @property_hash[:create_backup_unit] = group.properties.create_backup_unit

    sync_members(group.id, [], resource[:members])
  end

  def destroy
    Puppet.info("Deleting Group #{name}...")
    _, _, headers = Ionoscloud::UserManagementApi.new.um_group_delete_with_http_info(@property_hash[:id])
    PuppetX::Profitbricks::Helper::wait_request(headers)
    @property_hash[:ensure] = :absent
  end

  def flush
    changeable_fields = [:name, :create_backup_unit, :create_snapshot, :reserve_ip, :access_activity_log, :s3_privilege, :create_backup_unit]
    changes = Hash[*changeable_fields.collect {|v| [ v, @property_flush[v] ] }.flatten ].delete_if { |k, v| v.nil? || v == @property_hash[k] }
    return nil unless !changes.empty?

    group_properties = {
      name: @property_hash[:name],
      create_data_center: @property_hash[:create_data_center],
      create_snapshot: @property_hash[:create_snapshot],
      reserve_ip: @property_hash[:reserve_ip],
      access_activity_log: @property_hash[:access_activity_log],
      s3_privilege: @property_hash[:s3_privilege],
      create_backup_unit: @property_hash[:create_backup_unit],
    }

    puts "Updating group #{@property_hash[:name]} with #{changes}"

    new_group = Ionoscloud::Group.new(properties: Ionoscloud::GroupProperties.new(**group_properties.merge(changes)))

    _, _, headers = Ionoscloud::UserManagementApi.new.um_groups_put_with_http_info(@property_hash[:id], new_group)
    PuppetX::Profitbricks::Helper::wait_request(headers)
  end

  def sync_members(group_id, existing_members, target_members)
    to_wait = []

    target_members.each do |user|
      unless existing_members.include? user
        puts "Adding user #{user} to group #{group_id}"

        _, _, headers = Ionoscloud::UserManagementApi.new.um_groups_users_post_with_http_info(
          group_id,
          { id: PuppetX::Profitbricks::Helper::user_from_email(user).id },
        )

        to_wait << headers
      end
    end

    existing_members.each do |user|
      unless target_members.include? user
        puts "Removing user #{user} from group #{group_id}"

        _, _, headers = Ionoscloud::UserManagementApi.new.um_groups_users_delete_with_http_info(
          group_id,
          PuppetX::Profitbricks::Helper::user_from_email(user).id,
        )

        to_wait << headers
      end
    end


    to_wait.each { |headers| PuppetX::Profitbricks::Helper::wait_request(headers) }
  end

end
