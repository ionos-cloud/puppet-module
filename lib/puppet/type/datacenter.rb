
Puppet::Type.newtype(:datacenter) do
  @doc = 'Type representing a IonosCloud virtual data center.'
  @changeable_properties = [:description]

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the virtual data center where the server will reside.'
    isrequired
    validate do |value|
      raise('The name should be a String.') unless value.is_a?(String)
    end
  end

  newproperty(:description) do
    desc 'The data center description.'
    validate do |value|
      raise('Data center description must be a String') unless value.is_a?(String)
    end
  end

  newproperty(:sec_auth_protection) do
    desc 'Boolean value representing if the data center requires extra protection e.g. two factor protection.'
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:location) do
    desc 'The data center location.'
    isrequired
    validate do |value|
      raise('Data center location must be set') if value == ''
      raise('Data center location must be a String') unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  # read-only properties

  newproperty(:version) do
    desc 'The data center version.'

    def insync?(_is)
      true
    end
  end

  newproperty(:features, array_matching: :all) do
    desc 'List of features supported by the location this data center is part of.'

    def insync?(_is)
      true
    end
  end

  newproperty(:cpu_architecture, array_matching: :all) do
    desc 'Array of features and CPU families available in a location.'

    def insync?(_is)
      true
    end
  end

  newproperty(:id) do
    desc 'The data center ID.'

    def insync?(_is)
      true
    end
  end
end
