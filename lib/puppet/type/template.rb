Puppet::Type.newtype(:template) do
  @doc = 'Type representing available templates for CUBE servers.'

  newparam(:name, namevar: true) do
    desc 'The name of the template.'
  end

  newproperty(:cores) do
    desc 'The CPU cores count.'

    def insync?(_is)
      true
    end
  end

  newproperty(:ram) do
    desc 'The RAM size in MB.'

    def insync?(_is)
      true
    end
  end

  newproperty(:storage_size) do
    desc 'The storage size in GB.'

    def insync?(_is)
      true
    end
  end
end
