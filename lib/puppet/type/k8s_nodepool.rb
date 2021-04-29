require 'puppet/parameter/boolean'

Puppet::Type.newtype(:k8s_nodepool) do
  @doc = 'Type representing a Ionoscloud K8s Nodepool.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the K8s Nodepool.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:k8s_version) do
    desc 'The K8s version of the K8s Nodepool.'
    validate do |value|
      raise ArgumentError, 'The K8s version should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:maintenance_day) do
    desc 'The maintenance day of the K8s Nodepool.'
    validate do |value|
      raise ArgumentError, 'The maintenance day should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:maintenance_time) do
    desc 'The maintenance time of the K8s Nodepool.'
    validate do |value|
      raise ArgumentError, 'The maintenance time should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:datacenter_name) do
    desc 'The datacenter used by the K8s Nodepool.'
    validate do |value|
      raise ArgumentError, 'The datacenter name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:node_count) do
    desc 'The number of nodes in the nodepool.'
    validate do |value|
      numCores = Integer(value) rescue nil
      fail('You need to specify the number of nodes per nodepool') if value == ''
      fail('Node count must be a integer') unless numCores
    end
  end

  newproperty(:min_node_count) do
    desc 'The minimum number of nodes in the nodepool.'
    validate do |value|
      numCores = Integer(value) rescue nil
      fail('Minimum node count must be a integer') unless numCores
    end
  end

  newproperty(:max_node_count) do
    desc 'The maximum number of nodes in the nodepool.'
    validate do |value|
      numCores = Integer(value) rescue nil
      fail('Maximum node count must be a integer') unless numCores
    end
  end

  newproperty(:cpu_family) do
    desc 'The CPU family of the nodes.'
    defaultto 'AMD_OPTERON'
    newvalues('AMD_OPTERON', 'INTEL_XEON')

    validate do |value|
      unless ['AMD_OPTERON', 'INTEL_XEON'].include?(value)
        fail('CPU family must be either "AMD_OPTERON" or "INTEL_XEON"')
      end
      fail('CPU family must be a string') unless value.is_a?(String)
    end
  end

  newproperty(:cores_count) do
    desc 'The number of CPU cores assigned to the node.'
    validate do |value|
      numCores = Integer(value) rescue nil
      fail('Node must have cores assigned') if value == ''
      fail('Cores must be a integer') unless numCores
    end
  end

  newproperty(:ram) do
    desc 'The amount of RAM in MB assigned to the node.'
    validate do |value|
      ram = Integer(value) rescue nil
      fail('Node must have ram assigned') if value == ''
      fail('RAM must be a multiple of 256 MB') unless (ram % 256) == 0
    end
  end

  newproperty(:availability_zone) do
    desc 'The availability zone of where the server will reside.'
    defaultto 'AUTO'
    newvalues('AUTO', 'ZONE_1', 'ZONE_2')
  end

  newproperty(:storage_type) do
    desc 'The volume type.'
    defaultto 'HDD'
    newvalues('HDD', 'SSD')

    validate do |value|
      raise ArgumentError, 'The volume type should be a String.' unless value.is_a?(String)
    end

    def insync?(is)
      true
    end
  end

  newproperty(:storage_size) do
    desc 'The size of the volume in GB.'
    validate do |value|
      raise ArgumentError, 'The size of the volume must be an integer.' unless value.is_a?(Integer)
    end
  end

  newproperty(:lans, array_matching: :all) do
    desc 'The list of additional private LANs attached to worker nodes.'

    def insync?(is)
      # PuppetX::IonoscloudX::Helper::peers_match(is, should)
      puts [is, should].to_s
      false
    end
  end

  newproperty(:cluster_name) do
    desc 'The name of the K8s used by the K8s Nodepool.'
    validate do |value|
      raise ArgumentError, 'The cluster name should be a String.' unless value.is_a?(String)
    end
    def insync?(is)
      true
    end
  end

  # read-only properties

  newproperty(:id) do
    desc 'The ID of the K8s Nodepool.'
    def insync?(is)
      true
    end
  end

  newproperty(:datacenter_id) do
    desc 'The datacenter used by the K8s Nodepool.'
    def insync?(is)
      true
    end
  end

  newproperty(:cluster_id) do
    desc 'The ID of the K8s cluster of the K8s Nodepool.'
    def insync?(is)
      true
    end
  end
  newproperty(:state) do
    desc 'She state of the K8s Nodepool.'
    def insync?(is)
      true
    end
  end

  newproperty(:k8s_nodes, array_matching: :all) do
    desc 'A list of K8s nodes that exist in the nodepool.'
    def insync?(is)
      true
    end
  end
end