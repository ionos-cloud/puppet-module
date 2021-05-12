require 'puppet/parameter/boolean'

Puppet::Type.newtype(:pcc) do
  @doc = 'Type representing a ProfitBricks LAN.'

  newproperty(:ensure) do
    newvalue(:present) do
      provider.create unless provider.exists?
    end

    newvalue(:absent) do
      provider.destroy if provider.exists?
    end
  end

  newparam(:name, namevar: true) do
    desc 'The name of the PCC.'
    validate do |value|
      fail('The name should be a String') unless value.is_a?(String)
    end
  end

  newparam(:description) do
    desc 'The description of the PCC.'
    validate do |value|
      fail('The description should be a String') unless value.is_a?(String)
    end
  end

  newproperty(:peers, array_matching: :all) do
    desc 'The list of peers connected to the PCC.'

    def insync?(is)
      PuppetX::IonoscloudX::Helper::peers_match(is, should)
    end
  end

  # read-only properties

  newproperty(:id) do
    desc 'The PCC ID.'

    def insync?(is)
      true
    end
  end

  newproperty(:connectable_datacenters, array_matching: :all) do
    desc 'The datacenters from which you may connect to this PCC.'

    def insync?(is)
      true
    end
  end
end
