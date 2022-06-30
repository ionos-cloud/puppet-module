require 'puppet/parameter/boolean'

Puppet::Type.newtype(:target_group) do
  @doc = 'Type representing a IonosCloud Target Group.'
  @changeable_properties = [:algorithm, :protocol, :health_check, :http_health_check, :targets]
  @doc_directory = 'application-loadbalancer'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the Target Group.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:algorithm) do
    desc 'Algorithm for the balancing.'
    validate do |value|
      raise ArgumentError, 'The algorithm be an String.' unless value.is_a?(String)
    end
  end

  newproperty(:protocol) do
    desc 'Protocol of the balancing.'
    validate do |value|
      raise ArgumentError, 'The protocol be an String.' unless value.is_a?(String)
    end
  end

  newproperty(:health_check) do
    desc 'Health check attributes for Target Group.'
    validate do |value|
      raise ArgumentError, 'The Health check be an Hash.' unless value.is_a?(Hash)
    end

    def insync?(is)
      PuppetX::IonoscloudX::Helper.compare_objects(is, should)
    end
  end

  newproperty(:http_health_check) do
    desc 'Http health check attributes for Target Group.'
    validate do |value|
      raise ArgumentError, 'The Http health check be an Hash.' unless value.is_a?(Hash)
    end

    def insync?(is)
      PuppetX::IonoscloudX::Helper.compare_objects(is, should)
    end
  end

  newproperty(:targets, array_matching: :all) do
    desc 'Array of targets of the Target Group.'

    def insync?(is)
      PuppetX::IonoscloudX::Helper.compare_objects(is, should)
    end
  end

  # read-only properties

  newproperty(:id) do
    desc 'The Target Group ID.'

    def insync?(_is)
      true
    end
  end
end
