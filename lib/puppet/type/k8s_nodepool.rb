require 'time'
require 'puppet/parameter/boolean'

Puppet::Type.newtype(:k8s_nodepool) do
  @doc = 'Type representing a Ionoscloud K8s Nodepool.'
  @changeable_properties = [:k8s_version, :node_count, :maintenance_day, :maintenance_time, :min_node_count, :max_node_count, :lans]

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

  newproperty(:datacenter_name) do
    desc 'The datacenter used by the K8s Nodepool.'
    validate do |value|
      raise ArgumentError, 'The datacenter name should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:node_count) do
    desc 'The number of nodes in the nodepool.'
    validate do |value|
      begin
        Integer(value)
      rescue
        raise('Node count must be a integer')
      end
      raise('You need to specify the number of nodes per nodepool') if value == ''
    end
  end

  newproperty(:min_node_count) do
    desc 'The minimum number of nodes in the nodepool.'
    validate do |value|
      begin
        Integer(value)
      rescue
        raise('Minimum node count must be a integer')
      end
    end
  end

  newproperty(:max_node_count) do
    desc 'The maximum number of nodes in the nodepool.'
    validate do |value|
      begin
        Integer(value)
      rescue
        raise('Maximum node count must be a integer')
      end
    end
  end

  newproperty(:cpu_family) do
    desc 'The CPU family of the nodes.'
    defaultto 'AMD_OPTERON'
    newvalues('AMD_OPTERON', 'INTEL_XEON', 'INTEL_SKYLAKE')

    validate do |value|
      unless ['AMD_OPTERON', 'INTEL_XEON', 'INTEL_SKYLAKE'].include?(value)
        raise('CPU family must be either "AMD_OPTERON", "INTEL_SKYLAKE" or "INTEL_XEON"')
      end
      raise('CPU family must be a string') unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:cores_count) do
    desc 'The number of CPU cores assigned to the node.'
    validate do |value|
      begin
        Integer(value)
      rescue
        raise('Cores count must be a integer')
      end
      raise('Node must have cores assigned') if value == ''
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:ram_size) do
    desc 'The amount of RAM in MB assigned to the node.'
    validate do |value|
      begin
        ram_size = Integer(value)
      rescue
        raise('RAM size must be a integer')
      end
      raise('Node must have ram assigned') if value == ''
      raise('Requested Ram size must be set to multiple of 1024MB with a minimum of 2048MB') unless (ram_size % 1024) == 0 && ram_size >= 2048
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:availability_zone) do
    desc 'The availability zone of where the server will reside.'
    defaultto 'AUTO'
    newvalues('AUTO', 'ZONE_1', 'ZONE_2')

    def insync?(_is)
      true
    end
  end

  newproperty(:storage_type) do
    desc 'The volume type.'
    defaultto 'HDD'

    validate do |value|
      raise ArgumentError, 'The volume type should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:storage_size) do
    desc 'The size of the volume in GB.'
    validate do |value|
      raise ArgumentError, 'The size of the volume must be an integer.' unless value.is_a?(Integer)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:lans, array_matching: :all) do
    desc 'The list of additional private LANs attached to worker nodes.'

    def insync?(is)
      PuppetX::IonoscloudX::Helper.compare_objects(is, should)
    end
  end

  newproperty(:available_upgrade_versions, array_matching: :all) do
    desc 'List of available versions for upgrading the node pool.'
    def insync?(_is)
      true
    end
  end

  newproperty(:cluster_name) do
    desc 'The name of the K8s used by the K8s Nodepool.'
    validate do |value|
      raise ArgumentError, 'The cluster name should be a String.' unless value.is_a?(String)
    end
    def insync?(_is)
      true
    end
  end
  
  newproperty(:labels) do
    desc 'The map of labels attached to node pool.'

    def insync?(is)
      is == should
    end
  end

  newproperty(:annotations) do
    desc 'The map of annotations attached to node pool.'

    def insync?(is)
      is == should
    end
  end

  # read-only properties

  newproperty(:id) do
    desc 'The ID of the K8s Nodepool.'
    def insync?(_is)
      true
    end
  end

  newproperty(:datacenter_id) do
    desc 'The datacenter used by the K8s Nodepool.'
    def insync?(_is)
      true
    end
  end

  newproperty(:cluster_id) do
    desc 'The ID of the K8s cluster of the K8s Nodepool.'
    def insync?(_is)
      true
    end
  end
  newproperty(:state) do
    desc 'She state of the K8s Nodepool.'
    def insync?(_is)
      true
    end
  end

  newproperty(:k8s_nodes, array_matching: :all) do
    desc 'A list of K8s nodes that exist in the nodepool.'
    def insync?(_is)
      true
    end
  end
end
