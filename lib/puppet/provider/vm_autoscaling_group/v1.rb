require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:vm_autoscaling_group).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    super(*args)
    @property_flush = {}
  end

  def self.instances
    vm_autoscaling_groups = []
    PuppetX::IonoscloudX::Helper.vm_autoscaling_groups_api.autoscaling_groups_get(depth: 1).items.each do |group|
      vm_autoscaling_groups << new(instance_to_hash(group))
    end
    vm_autoscaling_groups.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:name] == prov.name
      end
    end
  end

  def self.instance_to_hash(instance, backups, postgres_versions)
    {
      id: instance.id,
      name: instance.properties.display_name,
      ensure: :present,
    }
  end

  
  
  
  
  
  policy

  def target_replica_count=(value)
    @property_flush[:target_replica_count] = value
  end

  def min_replica_count=(value)
    @property_flush[:min_replica_count] = value
  end

  def max_replica_count=(value)
    @property_flush[:max_replica_count] = value
  end

  def datacenter=(value)
    @property_flush[:datacenter] = value
  end

  def replica_configuration=(value)
    @property_flush[:replica_configuration] = value
  end

  def policy=(value)
    @property_flush[:policy] = value
  end

  def exists?
    Puppet.info("Checking if the VM ASutoscaling group '#{name}' exists.")
    @property_hash[:ensure] == :present
  end

  def create
    datacenter_id = get_datacenter_id(resource[:connections][0]['datacenter'])
    lan_id = get_lan_id(datacenter_id, resource[:connections][0]['lan'])

    group = PuppetX::IonoscloudX::Helper.vm_autoscaling_groups_api.autoscaling_groups_post(
      IonoscloudVmAutoscaling::Group(properties: IonoscloudVmAutoscaling::GroupProperties(
        name: resource[:name],
        instances: Integer(resource[:instances]),
        cores: Integer(resource[:cores_count]),
        ram: Integer(resource[:ram_size]),
        storage_size: Integer(resource[:storage_size]),
        storage_type: resource[:storage_type],
      )
    )

    cluster = PuppetX::IonoscloudX::Helper.dbaas_postgres_cluster_api.clusters_post(
      IonoscloudDbaasPostgres::CreateClusterRequest.new(properties: IonoscloudDbaasPostgres::CreateClusterProperties.new(
        postgres_version: resource[:postgres_version],
        instances: Integer(resource[:instances]),
        cores: Integer(resource[:cores_count]),
        ram: Integer(resource[:ram_size]),
        storage_size: Integer(resource[:storage_size]),
        storage_type: resource[:storage_type],
        connections: [
          IonoscloudDbaasPostgres::Connection.new(
            datacenter_id: datacenter_id,
            lan_id: String(lan_id),
            cidr: resource[:connections][0]['cidr'],
          ),
        ],
        location: resource[:location],
        display_name: resource[:display_name],
        maintenance_window: if resource[:maintenance_time] && resource[:maintenance_day]
                              IonoscloudDbaasPostgres::MaintenanceWindow.new(
                                      time: resource[:maintenance_time],
                                      day_of_the_week: resource[:maintenance_day],
                                    )
                            else
                              nil
                            end,
        credentials: IonoscloudDbaasPostgres::DBUser.new(
          username: resource[:db_username],
          password: resource[:db_password],
        ),
        synchronization_mode: resource[:synchronization_mode],
        from_backup: IonoscloudDbaasPostgres::CreateRestoreRequest.new(
          backup_id: resource[:backup_id],
          recovery_target_time: resource[:recovery_target_time],
        ),
      )),
    )

    Puppet.info("Created a new Postgres Cluster '#{display_name}'.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = cluster.id
  end

  def flush
    return if @property_flush.empty?
    changeable_properties = [:cores_count, :ram_size, :storage_size, :maintenance_time, :maintenance_day, :postgres_version, :instances]
    changes = Hash[ *changeable_properties.map { |property| [ property, @property_flush[property] ] }.flatten ].delete_if { |_k, v| v.nil? }

    return if changes.empty?

    Puppet.info("Updating Postgres Cluster '#{name}', #{changes.keys}.")

    cluster_request = IonoscloudDbaasPostgres::PatchClusterRequest.new(properties: IonoscloudDbaasPostgres::PatchClusterProperties.new(
      cores: (changes[:cores_count].nil? ? nil : Integer(changes[:cores_count])),
      ram: (changes[:ram_size].nil? ? nil : Integer(changes[:ram_size])),
      storage_size: (changes[:storage_size].nil? ? nil : Integer(changes[:storage_size])),
      maintenance_window: (if changes[:maintenance_time] || changes[:maintenance_day]
                             IonoscloudDbaasPostgres::MaintenanceWindow.new(
                                   time: (changes[:maintenance_time].nil? ? @property_hash[:maintenance_time] : changes[:maintenance_time]),
                                   day_of_the_week: (changes[:maintenance_day].nil? ? @property_hash[:maintenance_day] : changes[:maintenance_day]),
                                 )
                           else
                             nil
                           end),
      postgres_version: (changes[:postgres_version].nil? ? nil : changes[:postgres_version]),
      instances: (changes[:instances].nil? ? nil : Integer(changes[:instances])),
    ))

    PuppetX::IonoscloudX::Helper.dbaas_postgres_cluster_api.clusters_patch(@property_hash[:id], cluster_request)

    changeable_properties.each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
    @property_flush = {}
  end

  def destroy
    Puppet.info("Deleting VM ASutoscaling group '#{name}'...")
    PuppetX::IonoscloudX::Helper.vm_autoscaling_groups_api.autoscaling_groups_delete(@property_hash[:id])
    @property_hash[:ensure] = :absent
  end

  def get_datacenter_id(datacenter_id_or_name)
    return datacenter_id_or_name if PuppetX::IonoscloudX::Helper.validate_uuid_format(datacenter_id_or_name)
    PuppetX::IonoscloudX::Helper.resolve_datacenter_id(nil, datacenter_id_or_name)
  end

  def get_lan_id(datacenter_id, lan_id_or_name)
    return lan_id_or_name if lan_id_or_name.is_a? Integer
    PuppetX::IonoscloudX::Helper.lan_from_name(lan_id_or_name, datacenter_id).id
  end
end
