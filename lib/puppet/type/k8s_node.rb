require 'puppet/parameter/boolean'

Puppet::Type.newtype(:k8s_node) do
  @doc = 'Type representing a Ionoscloud network interface.'
  @doc_directory = 'kubernetes'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the K8s Node.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  # read-only properties

  newproperty(:public_ip) do
    desc 'The public IP of the K8s Node.'

    def insync?(_is)
      true
    end
  end

  newproperty(:k8s_version) do
    desc 'The K8s version of the K8s Node.'

    def insync?(_is)
      true
    end
  end

  newproperty(:private_ip) do
    desc 'The private IP of the K8s Node.'

    def insync?(_is)
      true
    end
  end

  newproperty(:state) do
    desc 'She state of the K8s Node.'

    def insync?(_is)
      true
    end
  end

  newproperty(:nodepool_id) do
    desc 'The K8s Nodepool ID the K8s Node will be attached to.'
    validate do |value|
      raise ArgumentError, 'The K8s Nodepool ID must be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:nodepool_name) do
    desc 'The K8s Nodepool name the K8s Node will be attached to.'
    validate do |value|
      raise ArgumentError, 'The K8s Nodepool name must be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:cluster_id) do
    desc 'The ID of the virtual K8s Cluster where the K8s Node will reside.'

    validate do |value|
      raise ArgumentError, 'The K8s Cluster ID should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:cluster_name) do
    desc 'The name of the virtual K8s Cluster where the K8s Node will reside.'

    validate do |value|
      raise ArgumentError, 'The K8s Cluster name should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  autorequire(:cluster_name) do
    self[:cluster_name]
  end
  autorequire(:nodepool_name) do
    self[:nodepool_name]
  end
end
