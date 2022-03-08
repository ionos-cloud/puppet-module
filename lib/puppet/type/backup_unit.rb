
Puppet::Type.newtype(:backup_unit) do
  @doc = 'Type representing a Ionoscloud Backup Unit'
  @changeable_properties = [:email]
  @doc_directory = 'backup'

  ensurable

  newparam(:name, namevar: true) do
    desc 'Alphanumeric name you want assigned to the backup unit.'
    isrequired
    validate do |value|
      raise('The name should be a String.') unless value.is_a?(String)
    end
  end

  newproperty(:email) do
    desc 'The e-mail address you want assigned to the backup unit.'
    isrequired
    validate do |value|
      raise('the Backup Unit email must be a String') unless value.is_a?(String)
    end
  end

  newproperty(:password) do
    desc 'Alphanumeric password you want assigned to the backup unit.'
    isrequired
    validate do |value|
      raise('the Backup Unit password must be a String') unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:id) do
    desc 'The Backup Unit ID.'

    def insync?(_is)
      true
    end
  end
end
