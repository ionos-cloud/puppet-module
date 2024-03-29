require 'puppet/parameter/boolean'

Puppet::Type.newtype(:networkloadbalancer) do
  @doc = 'Type representing a IonosCloud Network Load Balancer.'
  @changeable_properties = [:public_ips, :lans, :rules, :flowlogs]
  @doc_directory = 'compute-engine'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the Network Load Balancer.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:ips, array_matching: :all) do
    desc 'Collection of IP addresses of the Network Load Balancer. (inbound and outbound) IP of the listenerLan '\
    'must be a customer reserved IP for the public load balancer and private IP for the private load balancer.'

    def insync?(is)
      if is.is_a? Array
        is.sort == should.sort
      else
        is == should
      end
    end
  end

  newproperty(:lb_private_ips, array_matching: :all) do
    desc 'Collection of private IP addresses with subnet mask of the Network Load Balancer. IPs must contain valid '\
    'subnet mask. If user will not provide any IP then the system will generate one IP with /24 subnet.'

    def insync?(is)
      if is.is_a? Array
        is.sort == should.sort
      else
        is == should
      end
    end
  end

  newproperty(:listener_lan) do
    desc 'Id of the listening LAN. (inbound)'
    validate do |value|
      raise ArgumentError, 'The LAN ID must be an Integer.' unless value.is_a?(Integer)
    end
  end

  newproperty(:target_lan) do
    desc 'Id of the balanced private target LAN. (outbound)'
    validate do |value|
      raise ArgumentError, 'The LAN ID must be an Integer.' unless value.is_a?(Integer)
    end
  end

  newproperty(:rules, array_matching: :all) do
    desc 'A list of flow logs associated to the Network Load Balancer.'

    def insync?(is)
      PuppetX::IonoscloudX::Helper.objects_match(is, should, [:algorithm, :protocol, :listener_ip, :listener_port, :health_check, :targets])
    end
  end

  newproperty(:flowlogs, array_matching: :all) do
    desc 'A list of flow logs associated to the Network Load Balancer.'

    def insync?(is)
      PuppetX::IonoscloudX::Helper.objects_match(is, should, [:name, :action, :direction, :bucket])
    end
  end

  # read-only properties

  newproperty(:datacenter_id) do
    desc 'The ID of the virtual data center where the Network Load Balancer will reside.'

    validate do |value|
      raise ArgumentError, 'The data center ID should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:datacenter_name) do
    desc 'The name of the virtual data center where the Network Load Balancer will reside.'

    validate do |value|
      raise ArgumentError, 'The data center name should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:id) do
    desc 'The Network Load Balancer ID.'

    def insync?(_is)
      true
    end
  end

  autorequire(:datacenter) do
    self[:datacenter_name]
  end
end
