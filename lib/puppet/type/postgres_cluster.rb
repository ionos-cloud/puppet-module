require 'time'

Puppet::Type.newtype(:postgres_cluster) do
  @doc = 'Type representing a Ionoscloud DBaaS Postgres Cluster.'
  @changeable_properties = [:cores_count, :ram_size, :storage_size, :maintenance_time, :maintenance_day, :postgres_version, :instances]
  @doc_directory = 'dbaas-postgres'

  ensurable

  newparam(:display_name, namevar: true) do
    desc 'The name of the Postgres Cluster.'
    validate do |value|
      raise ArgumentError, 'The display_name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:restore) do
    desc 'If true, restore the Cluster to the backup specified by backup_id and the time specified by recovery_target_time.'
    newvalues(:true, :false)
    def insync?(_is)
      should.to_s != 'true'
    end
  end

  newproperty(:postgres_version) do
    desc 'The Postgres version of the Postgres Cluster.'
    isrequired
    validate do |value|
      raise ArgumentError, 'The Postgres version should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:maintenance_day) do
    desc 'The maintenance day of the Postgres Cluster.'
    validate do |value|
      raise ArgumentError, 'The maintenance day should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:maintenance_time) do
    desc 'The maintenance time of the Postgres Cluster.'
    validate do |value|
      raise ArgumentError, 'The maintenance time should be a String.' unless value.is_a?(String)
      begin
        Time.parse(value)
      rescue
        raise ArgumentError, 'The maintenance time is not valid.'
      end
    end

    def insync?(is)
      Time.parse(is) - Time.parse(should) < 15 * 60.0
    end
  end

  newproperty(:instances) do
    desc 'The total number of instances in the cluster (one master and n-1 standbys).'
    isrequired
    validate do |value|
      begin
        Integer(value)
      rescue
        raise('Instances must be a integer')
      end
      raise('You need to specify the number of instances') if value == ''
    end
  end

  newproperty(:cores_count) do
    desc 'The number of CPU cores assigned to the instances.'
    isrequired
    validate do |value|
      begin
        Integer(value)
      rescue
        raise('Cores count must be a integer')
      end
      raise('Instances must have cores assigned') if value == ''
    end
  end

  newproperty(:ram_size) do
    desc 'The amount of RAM in MB assigned to the instances.'
    isrequired
    validate do |value|
      begin
        ram_size = Integer(value)
      rescue
        raise('RAM size must be a integer')
      end
      raise('Instances must have ram assigned') if value == ''
      raise('Requested Ram size must be set to multiple of 1024MB') unless (ram_size % 1024) == 0
    end
  end

  newproperty(:storage_size) do
    desc 'The size of the volume in GB.'
    isrequired
    validate do |value|
      raise ArgumentError, 'The size of the volume must be an integer.' unless value.is_a?(Integer)
    end
  end

  newproperty(:storage_type) do
    desc 'The volume type.'
    isrequired

    validate do |value|
      raise ArgumentError, 'The volume type should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:location) do
    desc 'The Postgres Cluster location.'
    isrequired
    validate do |value|
      raise('Postgres Cluster location must be set') if value == ''
      raise('Postgres Cluster location must be a String') unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:backup_location) do
    desc 'The S3 location where the backups will be stored.'
    validate do |value|
      raise('Postgres Cluster backup_location must be a String') unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:synchronization_mode) do
    desc 'Represents different modes of replication.'
    isrequired
    validate do |value|
      raise('Syncronization mode must be set') if value == ''
      raise('Syncronization mode must be a String') unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:connections, array_matching: :all) do
    desc 'An array of connections to the Postgres Cluster.'
    isrequired
    validate do |value|
      connections = value.is_a?(Array) ? value : [value]
      connections.each do |_connection|
        ['datacenter', 'lan', 'cidr'].each do |key|
          raise("Connection must include #{key}") unless value.keys.include?(key)
        end
      end
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:db_username) do
    desc 'The username for the initial postgres user. Some system usernames are restricted (e.g. "postgres", "admin", "standby")'
    isrequired
    validate do |value|
      raise ArgumentError, 'The image password should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:db_password) do
    desc 'The password for the initial postgres user.'
    validate do |value|
      raise ArgumentError, 'The image password should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:backup_id) do
    desc 'ID of a backup for the Cluster'
    validate do |value|
      raise ArgumentError, 'The Backup ID should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:recovery_target_time) do
    desc 'Recovery target time'
    validate do |value|
      raise ArgumentError, 'The Recovery target time should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  # read-only properties

  newproperty(:id) do
    desc 'The ID of the Postgres Cluster.'
    def insync?(_is)
      true
    end
  end

  newproperty(:state) do
    desc 'The state of the Postgres Cluster.'
    def insync?(_is)
      true
    end
  end

  newproperty(:backups, array_matching: :all) do
    desc 'A list of backups that exist in the Postgres Cluster.'
    def insync?(_is)
      true
    end
  end

  newproperty(:available_postgres_vesions, array_matching: :all) do
    desc 'A list of Postgres Versions available for the Postgres Cluster.'
    def insync?(_is)
      true
    end
  end
end
