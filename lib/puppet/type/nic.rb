require 'puppet/parameter/boolean'

Puppet::Type.newtype(:nic) do
  @doc = 'Type representing a IonosCloud network interface.'
  @changeable_properties = [:ips, :lan, :dhcp, :firewall_active, :firewall_rules, :firewall_type, :flowlogs]
  @doc_directory = 'compute-engine'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the NIC.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:ips, array_matching: :all) do
    desc 'The IPs assigned to the NIC.'

    def insync?(is)
      if is.is_a? Array
        is.sort == should.sort
      else
        is == should
      end
    end
  end

  newproperty(:dhcp) do
    desc 'Enable or disable DHCP on the NIC.'
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:lan) do
    desc 'The LAN name the NIC will sit on.'
    validate do |value|
      raise ArgumentError, 'The LAN name must be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:firewall_rules, array_matching: :all) do
    desc 'A list of firewall rules associated to the NIC.'

    def insync?(is)
      PuppetX::IonoscloudX::Helper.objects_match(is, should, [:type, :source_mac, :source_ip, :target_ip, :port_range_start, :port_range_end, :icmp_type, :icmp_code])
    end
  end

  newproperty(:flowlogs, array_matching: :all) do
    desc 'A list of flow logs associated to the NIC.'

    def insync?(is)
      PuppetX::IonoscloudX::Helper.objects_match(is, should, [:name, :action, :direction, :bucket])
    end
  end

  newproperty(:firewall_active) do
    desc 'Indicates the firewall is active.'
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:firewall_type) do
    desc 'Indicates the firewall is active.'
    validate do |value|
      raise ArgumentError, 'The LAN name must be a String.' unless value.is_a?(String)
    end
  end

  # read-only properties

  newproperty(:device_number) do
    desc 'The LUN ID of the storage volume. Null for volumes not mounted to any VM'

    def insync?(_is)
      true
    end
  end

  newproperty(:pci_slot) do
    desc 'The PCI slot number of the storage volume. Null for volumes not mounted to any VM'

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

  newproperty(:id) do
    desc 'The NIC ID.'

    def insync?(_is)
      true
    end
  end

  autorequire(:datacenter) do
    self[:datacenter_name]
  end
  autorequire(:server) do
    self[:server_name]
  end
end
