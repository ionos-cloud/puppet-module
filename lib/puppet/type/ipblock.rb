Puppet::Type.newtype(:ipblock) do
  @doc = 'Type representing a IonosCloud IP block.'
  @changeable_properties = [:firstname, :lastname, :administrator, :force_sec_auth, :groups]
  @doc_directory = 'compute-engine'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the IP block.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  # create-time set properties

  newproperty(:location) do
    desc "The IP block's location."
    validate do |value|
      raise ArgumentError, 'IP block location must be set' if value.nil? || (value == '')
      raise ArgumentError, 'IP block location must be a String' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:size) do
    desc 'The size of the IP block.'
    validate do |value|
      unless value.is_a?(Integer) && (value > 0)
        raise ArgumentError, 'The size of the IP block must be an integer greater than zero.'
      end
    end

    def insync?(_is)
      true
    end
  end

  # read-only properties

  newproperty(:id) do
    desc "The IP block's ID."

    def insync?(_is)
      true
    end
  end

  newproperty(:created_by) do
    desc 'The user who created the IP block.'

    def insync?(_is)
      true
    end
  end

  newproperty(:ips, array_matching: :all) do
    desc 'The IPs allocated to the IP block.'

    def insync?(_is)
      true
    end
  end

  newproperty(:ip_consumers, array_matching: :all) do
    desc 'Read-Only attribute. Lists consumption detail of an individual ip'

    def insync?(_is)
      true
    end
  end
end
