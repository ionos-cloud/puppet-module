require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:postgres_cluster).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    super(*args)
    @property_flush = {}
  end

  def self.instances
    postgres_clusters = []
    PuppetX::IonoscloudX::Helper.dbaas_postgres_cluster_api.clusters_get(depth: 1).items.each do |postgres_cluster|
      backups = PuppetX::IonoscloudX::Helper.dbaas_postgres_backup_api.cluster_backups_get(postgres_cluster.id)
      postgres_clusters << new(instance_to_hash(postgres_cluster, backups))
    end
    postgres_clusters.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:display_name] == prov.name
      end
    end
  end

  def self.instance_to_hash(instance, backups)
    {
      id: instance.id,
      postgres_version: instance.properties.postgres_version,
      instances: instance.properties.instances,
      cores_count: instance.properties.cores,
      ram_size: instance.properties.ram,
      storage_size: instance.properties.storage_size,
      storage_type: instance.properties.storage_type,
      connections: instance.properties.connections,
      location: instance.properties.location,
      display_name: instance.properties.display_name,
      name: instance.properties.display_name,
      maintenance_day: instance.properties.maintenance_window.day_of_the_week,
      maintenance_time: instance.properties.maintenance_window.time,
      synchronization_mode: instance.properties.synchronization_mode,
      state: instance.metadata.state,
      backups: backups.items.map do |backup|
        {
          id: backup.id,
          version: backup.properties.version,
          is_active: backup.properties.is_active,
          earliest_recovery_target_time: backup.properties.earliest_recovery_target_time,
        }
      end,
      ensure: :present,
    }
  end

  def restore=(_value)
    # restore setter is only invoked on restore => true

    PuppetX::IonoscloudX::Helper.dbaas_postgres_restore_api.cluster_restore_post(
      @property_hash[:id], 
      restore_request = IonoscloudDbaasPostgres::CreateRestoreRequest.new(
        backup_id: resource[:backup_id],
        recovery_target_time: resource[:recovery_target_time],
      ),
    )

    Puppet.info("Restoring backup '#{resource[:backup_id]}' onto Postgres Cluster '#{name}'")
  end

  def cores_count=(value)
    @property_flush[:cores_count] = value
  end

  def ram_size=(value)
    @property_flush[:ram_size] = value
  end

  def storage_size=(value)
    @property_flush[:storage_size] = value
  end

  def maintenance_time=(value)
    @property_flush[:maintenance_time] = value
  end

  def maintenance_day=(value)
    @property_flush[:maintenance_day] = value
  end

  def postgres_version=(value)
    @property_flush[:postgres_version] = value
  end

  def instances=(value)
    @property_flush[:instances] = value
  end

  def exists?
    Puppet.info("Checking if snapshot '#{name}' exists.")
    @property_hash[:ensure] == :present
  end

  def create
    datacenter_id = get_datacenter_id(resource[:connections][0]['datacenter'])
    lan_id = get_lan_id(datacenter_id, resource[:connections][0]['lan'])

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
        maintenance_window: (resource[:maintenance_time] && resource[:maintenance_day]) ? IonoscloudDbaasPostgres::MaintenanceWindow.new(
          time: resource[:maintenance_time],
          day_of_the_week: resource[:maintenance_day],
        ) : nil,
        credentials: IonoscloudDbaasPostgres::DBUser.new(
          username: resource[:db_username],
          password: resource[:db_password],
        ),
        synchronization_mode: resource[:synchronization_mode],
        from_backup: IonoscloudDbaasPostgres::CreateRestoreRequest.new(
          backup_id: resource[:backup_id],
          recovery_target_time: resource[:recovery_target_time],
        ),
      ))
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
      maintenance_window: IonoscloudDbaasPostgres::MaintenanceWindow.new(
        time: (changes[:maintenance_time].nil? ? @property_hash[:maintenance_time] : changes[:maintenance_time]),
        day_of_the_week: (changes[:maintenance_day].nil? ? @property_hash[:maintenance_day] : changes[:maintenance_day]),
      ),
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
    Puppet.info("Deleting Postgres Cluster '#{name}'...")
    PuppetX::IonoscloudX::Helper.dbaas_postgres_cluster_api.clusters_delete(@property_hash[:id])
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
