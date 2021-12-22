require 'ipaddr'
require 'time'
require 'puppet/parameter/boolean'

Puppet::Type.newtype(:k8s_cluster) do
  @doc = 'Type representing a Ionoscloud K8s Cluster.'
  @changeable_properties = [
    :k8s_version, :maintenance_day, :maintenance_time,
    :api_subnet_allow_list, :s3_buckets
  ]

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the K8s Cluster.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:k8s_version) do
    desc 'The K8s version of the K8s Cluster.'
    validate do |value|
      raise ArgumentError, 'The K8s version should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:maintenance_day) do
    desc 'The maintenance day of the K8s Cluster.'
    validate do |value|
      raise ArgumentError, 'The maintenance day should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:maintenance_time) do
    desc 'The maintenance time of the K8s Cluster.'
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

  newproperty(:api_subnet_allow_list, array_matching: :all) do
    desc 'Access to the K8s API server is restricted to these CIDRs. Cluster-internal traffic '\
    'is not affected by this restriction. If no allowlist is specified, access is not restricted. '\
    'If an IP without subnet mask is provided, the default value will be used: 32 for IPv4 and 128 for IPv6.'

    def insync?(is)
      PuppetX::IonoscloudX::Helper.compare_objects(is, should)
    end
  end

  newproperty(:s3_buckets, array_matching: :all) do
    desc 'List of S3 bucket configured for K8s usage. For now it contains only an S3 bucket used to store K8s API audit logs'

    def insync?(is)
      PuppetX::IonoscloudX::Helper.compare_objects(is, should)
    end
  end

  # read-only properties

  newproperty(:id) do
    desc 'The ID of the K8s Cluster.'
    def insync?(_is)
      true
    end
  end

  newproperty(:state) do
    desc 'She state of the K8s Cluster.'
    def insync?(_is)
      true
    end
  end

  newproperty(:k8s_nodepools, array_matching: :all) do
    desc 'A list of K8s nodepool that exist in the cluster.'
    def insync?(_is)
      true
    end
  end

  newproperty(:available_upgrade_versions, array_matching: :all) do
    desc 'List of available versions for upgrading the cluster.'
    def insync?(_is)
      true
    end
  end

  newproperty(:viable_node_pool_versions, array_matching: :all) do
    desc 'List of versions that may be used for node pools under this cluster.'
    def insync?(_is)
      true
    end
  end
end
