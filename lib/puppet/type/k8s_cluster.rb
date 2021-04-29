require 'puppet/parameter/boolean'

Puppet::Type.newtype(:k8s_cluster) do
  @doc = 'Type representing a Ionoscloud K8s Cluster.'

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
    end
  end

  # read-only properties

  newproperty(:id) do
    desc 'The ID of the K8s Cluster.'
    def insync?(is)
      true
    end
  end

  newproperty(:state) do
    desc 'She state of the K8s Cluster.'
    def insync?(is)
      true
    end
  end

  newproperty(:k8s_nodepools, array_matching: :all) do
    desc 'A list of K8s nodepool that exist in the cluster.'
    def insync?(is)
      true
    end
  end
end