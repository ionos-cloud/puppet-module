require 'puppet/parameter/boolean'

Puppet::Type.newtype(:natgateway) do
  @doc = 'Type representing a IonosCloud NAT Gateway.'
  @changeable_properties = [:public_ips, :lans, :rules, :flowlogs]
  @doc_directory = 'compute-engine'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the NAT Gateway.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:public_ips, array_matching: :all) do
    desc 'Collection of public IP addresses of the NAT gateway. Should be customer reserved IP addresses in that location.'

    def insync?(is)
      if is.is_a? Array
        is.sort == should.sort
      else
        is == should
      end
    end
  end

  newproperty(:lans, array_matching: :all) do
    desc 'Collection of LANs connected to the NAT gateway. IPs must contain valid subnet mask. '\
    'If user will not provide any IP then system will generate an IP with /24 subnet.'

    def insync?(is)
      comp = ->(a, b) { a['id'] <=> b['id'] }
      is.sort(&comp) == should.sort(&comp)
    end
  end

  newproperty(:rules, array_matching: :all) do
    desc 'A list of flow logs associated to the NAT Gateway.'

    def insync?(is)
      PuppetX::IonoscloudX::Helper.objects_match(is, should, [:protocol, :public_ip, :source_subnet, :target_subnet, :target_port_range])
    end
  end

  newproperty(:flowlogs, array_matching: :all) do
    desc 'A list of flow logs associated to the NAT Gateway.'

    def insync?(is)
      PuppetX::IonoscloudX::Helper.objects_match(is, should, [:name, :action, :direction, :bucket])
    end
  end

  # read-only properties

  newproperty(:datacenter_id) do
    desc 'The ID of the virtual data center where the NAT Gateway will reside.'

    validate do |value|
      raise ArgumentError, 'The data center ID should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:datacenter_name) do
    desc 'The name of the virtual data center where the NAT Gateway will reside.'

    validate do |value|
      raise ArgumentError, 'The data center name should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:id) do
    desc 'The NAT Gateway ID.'

    def insync?(_is)
      true
    end
  end

  autorequire(:datacenter) do
    self[:datacenter_name]
  end
end
