require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:backup_unit).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    PuppetX::IonoscloudX::Helper::ionoscloud_config
    super(*args)
  end

  def self.instances
    PuppetX::IonoscloudX::Helper::ionoscloud_config
    backup_units = []
    Ionoscloud::BackupUnitApi.new.backupunits_get(depth: 1).items.each do |backup_unit|
      # Ignore backup units if name is not defined.
      backup_units << new(instance_to_hash(backup_unit)) unless backup_unit.properties.name.nil? || backup_unit.properties.name.empty?
    end
    backup_units.flatten
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
      email: instance.properties.email,
      password: instance.properties.password,
      ensure: :present,
    }
  end

  def email=(value)
    Puppet.info("Updating backup unit '#{resource[:name]}' email.")

    backup_unit = Ionoscloud::BackupUnitProperties.new(email: value)

    backup_unit, _, headers = Ionoscloud::BackupUnitApi.new.backupunits_patch_with_http_info(@property_hash[:id], backup_unit)
    PuppetX::IonoscloudX::Helper::wait_request(headers)

    @property_hash[:email] = backup_unit.properties.email
  end

  def exists?
    Puppet.info("Checking if backup unit #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def create
    Puppet.info("Creating a new backupunit named #{resource[:name]}.")

    backup_unit = Ionoscloud::BackupUnit.new(
      properties: Ionoscloud::BackupUnitProperties.new(
        name: resource[:name],
        email: resource[:email],
        password: resource[:password],
      ),
    )
    backup_unit, _, headers = Ionoscloud::BackupUnitApi.new.backupunits_post_with_http_info(backup_unit)
    PuppetX::IonoscloudX::Helper::wait_request(headers)

    @property_hash[:ensure] = :present
    @property_hash[:id] = backup_unit.id
  end

  def destroy
    Puppet.info("Deleting backup unit #{resource[:name]}.")
    
    _, _, headers = Ionoscloud::BackupUnitApi.new.backupunits_delete_with_http_info(@property_hash[:id])
    PuppetX::IonoscloudX::Helper::wait_request(headers)

    @property_hash[:ensure] = :absent
  end
end
