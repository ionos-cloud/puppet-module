require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:ionoscloud_user).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    super(*args)
    @property_flush = {}
  end

  def self.instances
    users = []
    PuppetX::IonoscloudX::Helper.user_management_api.um_users_get(depth: 3).items.each do |user|
      users << new(instance_to_hash(user))
    end
    users.flatten
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
      name: instance.properties.email,
      email: instance.properties.email,
      firstname: instance.properties.firstname,
      lastname: instance.properties.lastname,
      administrator: instance.properties.administrator,
      force_sec_auth: instance.properties.force_sec_auth,
      sec_auth_active: instance.properties.sec_auth_active,
      groups: instance.entities.groups.items.map { |group| group.properties.name },
      ensure: :present,
    }
  end

  def firstname=(value)
    @property_flush[:firstname] = value
  end

  def lastname=(value)
    @property_flush[:lastname] = value
  end

  def administrator=(value)
    @property_flush[:administrator] = value
  end

  def force_sec_auth=(value)
    @property_flush[:force_sec_auth] = value
  end

  def groups=(value)
    sync_groups(@property_hash[:id], @property_hash[:groups], value)
    @property_hash[:groups] = value
  end

  def exists?
    Puppet.info("Checking if ionoscloud user #{name} exists.")
    @property_hash[:ensure] == :present
  end

  def create
    user = Ionoscloud::UserPost.new(
      properties: Ionoscloud::UserPropertiesPost.new(
        firstname: resource[:firstname],
        lastname: resource[:lastname],
        email: resource[:email],
        password: resource[:password],
        administrator: resource[:administrator],
        force_sec_auth: resource[:force_sec_auth],
      ),
    )

    user, _, headers = PuppetX::IonoscloudX::Helper.user_management_api.um_users_post_with_http_info(user)
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    Puppet.info("Created new ionoscloud user #{name}.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = user.id
    @property_hash[:firstname] = user.properties.firstname
    @property_hash[:lastname] = user.properties.lastname
    @property_hash[:email] = user.properties.email
    @property_hash[:administrator] = user.properties.administrator
    @property_hash[:force_sec_auth] = user.properties.force_sec_auth

    sync_groups(user.id, [], resource[:groups])
  end

  def destroy
    Puppet.info("Deleting user #{name}...")
    _, _, headers = PuppetX::IonoscloudX::Helper.user_management_api.um_users_delete_with_http_info(@property_hash[:id])
    PuppetX::IonoscloudX::Helper.wait_request(headers)
    @property_hash[:ensure] = :absent
  end

  def flush
    return if @property_flush.empty?
    changeable_properties = [:firstname, :lastname, :administrator, :force_sec_auth]
    changes = Hash[*changeable_properties.map { |v| [ v, @property_flush[v] ] }.flatten ].delete_if { |k, v| v.nil? || v == @property_hash[k] }
    return nil unless !changes.empty?

    user_properties = {
      firstname: @property_hash[:firstname],
      lastname: @property_hash[:lastname],
      email: @property_hash[:email],
      administrator: @property_hash[:administrator],
      force_sec_auth: @property_hash[:force_sec_auth],
    }

    Puppet.info "Updating user #{@property_hash[:email]} with #{changes}"

    new_user = Ionoscloud::UserPut.new(properties: Ionoscloud::UserPropertiesPut.new(**user_properties.merge(changes)))

    _, _, headers = PuppetX::IonoscloudX::Helper.user_management_api.um_users_put_with_http_info(@property_hash[:id], new_user)
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    changeable_properties.each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
    @property_flush = {}
  end

  def sync_groups(user_id, existing_groups, target_groups)
    to_wait = []

    unless target_groups.nil?
      target_groups.each do |group|
        next if !existing_groups.nil? && existing_groups.include?(group)
        Puppet.info "Adding user #{user_id} to group #{group}"

        _, _, headers = PuppetX::IonoscloudX::Helper.user_management_api.um_groups_users_post_with_http_info(
          PuppetX::IonoscloudX::Helper.group_from_name(group).id,
          { id: user_id },
        )

        to_wait << headers
      end
    end

    unless existing_groups.nil?
      existing_groups.each do |group|
        next if !target_groups.nil? && target_groups.include?(group)
        Puppet.info "Removing user #{user_id} from group #{group}"

        _, _, headers = PuppetX::IonoscloudX::Helper.user_management_api.um_groups_users_delete_with_http_info(
          PuppetX::IonoscloudX::Helper.group_from_name(group).id,
          user_id,
        )

        to_wait << headers
      end
    end

    to_wait.each { |headers| PuppetX::IonoscloudX::Helper.wait_request(headers) }
  end
end
