Puppet::Type.newtype(:firewall_rule) do
  @doc = 'Type representing a IonosCloud firewall rule.'
  @changeable_properties = [:icmp_code, :icmp_type, :port_range_start, :port_range_end, :source_mac, :source_ip, :target_ip, :type]
  @doc_directory = 'compute-engine'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the firewall rule.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:source_mac) do
    desc 'Only traffic originating from the respective MAC address is allowed. Valid format: aa:bb:cc:dd:ee:ff.'
    validate do |value|
      raise ArgumentError, 'The source mac address must be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:source_ip) do
    desc 'Only traffic originating from the respective IPv4 address is allowed.'
    validate do |value|
      raise ArgumentError, 'The source IP must be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:target_ip) do
    desc 'In case the target NIC has multiple IP addresses, only traffic directed to the respective IP address of the NIC is allowed.'
    validate do |value|
      raise ArgumentError, 'The target IP must be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:port_range_start) do
    desc 'Defines the start range of the allowed port (from 1 to 65534) if protocol TCP or UDP is chosen.'

    validate do |value|
      raise ArgumentError, 'The target Port must be an Integer.' unless value.is_a?(Integer)
    end

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:port_range_end) do
    desc 'Defines the end range of the allowed port (from 1 to 65534) if the protocol TCP or UDP is chosen.'

    validate do |value|
      raise ArgumentError, 'The target Port must be an Integer.' unless value.is_a?(Integer)
    end

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:icmp_type) do
    desc 'Defines the allowed type (from 0 to 254) if the protocol ICMP is chosen.'

    validate do |value|
      raise ArgumentError, 'The ICMP type must be an Integer.' unless value.is_a?(Integer)
    end

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:icmp_code) do
    desc 'Defines the allowed code (from 0 to 254) if protocol ICMP is chosen.'

    validate do |value|
      raise ArgumentError, 'The ICMP code must be an Integer.' unless value.is_a?(Integer)
    end

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:type) do
    desc 'The type of firewall rule. If is not specified, it will take the default value INGRESS.'

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  # read-only properties

  newproperty(:protocol) do
    desc 'The protocol for the firewall rule.'
    newvalues('TCP', 'UDP', 'ICMP', 'ANY')

    validate do |value|
      raise ArgumentError, 'The protocol must be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:datacenter_id) do
    desc 'The ID of the virtual data center where the NIC will reside.'

    validate do |value|
      raise ArgumentError, 'The data center ID should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:datacenter_name) do
    desc 'The name of the virtual data center where the NIC will reside.'

    validate do |value|
      raise ArgumentError, 'The data center name should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:server_id) do
    desc 'The server ID the NIC will be attached to.'
    validate do |value|
      raise ArgumentError, 'The server ID must be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:server_name) do
    desc 'The server name the NIC will be attached to.'
    validate do |value|
      raise ArgumentError, 'The server name must be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:nic_id) do
    desc 'The NIC ID the NIC will be attached to.'
    validate do |value|
      raise ArgumentError, 'The NIC ID must be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:nic_name) do
    desc 'The name of the NIC the firewall rule will be added to.'
    validate do |value|
      raise ArgumentError, 'The NIC name must be a String.' unless value.is_a?(String)
    end
  end

  autorequire(:nic_name) do
    self[:nic_name]
  end

  newproperty(:id) do
    desc 'The Firewall Rule ID.'

    def insync?(_is)
      true
    end
  end
end
