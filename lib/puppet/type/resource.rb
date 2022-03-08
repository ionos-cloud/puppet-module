Puppet::Type.newtype(:resource) do
  @doc = 'Type representing a IonosCloud resource.'
  @doc_directory = 'compute-engine'

  newparam(:name, namevar: true) do
    desc 'The name of the resource.'
  end

  newproperty(:id) do
    desc 'The ID of the resource.'

    def insync?(_is)
      true
    end
  end

  newproperty(:type) do
    desc "The resource's type."

    def insync?(_is)
      true
    end
  end
end
