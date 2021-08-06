require 'puppet/parameter/boolean'

Puppet::Type.newtype(:application_loadbalancer) do
  @doc = 'Type representing a IonosCloud Application Load Balancer.'
  @changeable_properties = [:public_ips, :lans, :rules, :flowlogs]

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the Application Load Balancer.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:listener_lan) do
    desc 'Id of the listening LAN. (inbound)'
    validate do |value|
      raise ArgumentError, 'The LAN ID must be an Integer.' unless value.is_a?(Integer)
    end
  end

  newproperty(:ips, array_matching: :all) do
    desc 'Collection of IP addresses of the Application Load Balancer. (inbound and outbound) IP of the listenerLan must '\
    'be a customer reserved IP for the public load balancer and private IP for the private load balancer.'

    def insync?(is)
      if is.is_a? Array
        is.sort == should.sort
      else
        is == should
      end
    end
  end

  newproperty(:target_lan) do
    desc 'Id of the balanced private target LAN. (outbound)'
    validate do |value|
      raise ArgumentError, 'The LAN ID must be an Integer.' unless value.is_a?(Integer)
    end
  end

  newproperty(:lb_private_ips, array_matching: :all) do
    desc 'Collection of private IP addresses with subnet mask of the Application Load Balancer. IPs must contain valid subnet mask. '\
    'If user will not provide any IP then the system will generate one IP with /24 subnet.'

    def insync?(is)
      if is.is_a? Array
        is.sort == should.sort
      else
        is == should
      end
    end
  end

  newproperty(:rules, array_matching: :all) do
    desc 'A list of flow logs associated to the Application Load Balancer.'

    def insync?(is)
      PuppetX::IonoscloudX::Helper.objects_match(
        is, should, [:protocol, :listener_ip, :listener_port, :health_check, :server_certificates, :http_rules],
      )
    end
  end

  # read-only properties

  newproperty(:datacenter_id) do
    desc 'The ID of the virtual data center where the Application Load Balancer will reside.'

    validate do |value|
      raise ArgumentError, 'The data center ID should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:datacenter_name) do
    desc 'The name of the virtual data center where the Application Load Balancer will reside.'

    validate do |value|
      raise ArgumentError, 'The data center name should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:id) do
    desc 'The Application Load Balancer ID.'

    def insync?(_is)
      true
    end
  end

  autorequire(:datacenter) do
    self[:datacenter_name]
  end
end
