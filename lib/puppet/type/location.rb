Puppet::Type.newtype(:location) do
  @doc = 'Type representing a IonosCloud location.'
  @doc_directory = 'compute-engine'

  newparam(:name, namevar: true) do
    desc 'The name of the location.'
  end

  # read-only properties

  newproperty(:id) do
    desc 'The ID of the location.'

    def insync?(_is)
      true
    end
  end

  newproperty(:features, array_matching: :all) do
    desc 'A list of features available at the location.'

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

  newproperty(:image_aliases, array_matching: :all) do
    desc 'A list of image aliases available at the location.'

    def insync?(_is)
      true
    end
  end
end
