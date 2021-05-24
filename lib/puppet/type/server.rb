require 'puppet/parameter/boolean'

require_relative '../../puppet_x/ionoscloud/helper'

Puppet::Type.newtype(:server) do
  @doc = 'Type representing a IonosCloud server.'
  @changeable_properties = [:cores, :cpu_family, :ram, :availability_zone, :boot_volume, :volumes, :nics]

  newproperty(:ensure) do
    newvalue(:present) do
      provider.create unless provider.running?
    end

    newvalue(:absent) do
      provider.destroy if provider.exists?
    end

    newvalue(:running) do
      provider.create unless provider.running?
    end

    newvalue(:stopped) do
      provider.stop unless provider.stopped?
    end

    def change_to_s(current, desired)
      current = :running if current == :present
      desired = :running if desired == :present
      current == desired ? current : "changed #{current} to #{desired}"
    end

    def insync?(is)
      is = :present if is == :running
      is = :stopped if is == :stopping
      is.to_s == should.to_s
    end
  end

  newparam(:name, namevar: true) do
    desc 'The name of the server.'
    validate do |value|
      raise('Server must have a name') if value == ''
      raise('Name should be a String') unless value.is_a?(String)
    end
  end

  newproperty(:datacenter_id) do
    desc 'The virtual data center where the server will reside.'

    def insync?(_is)
      true
    end
  end

  newproperty(:datacenter_name) do
    desc 'The name of the virtual data center where the server will reside.'

    def insync?(_is)
      true
    end
  end

  newproperty(:cores) do
    desc 'The number of CPU cores assigned to the server.'
    validate do |value|
      begin
        Integer(value)
      rescue
        raise('Cores must be a integer')
      end
      raise('Server must have cores assigned') if value == ''
    end
  end

  newproperty(:cpu_family) do
    desc 'The CPU family of the server.'
    defaultto 'AMD_OPTERON'
    newvalues('AMD_OPTERON', 'INTEL_XEON')

    validate do |value|
      unless ['AMD_OPTERON', 'INTEL_XEON'].include?(value)
        raise('CPU family must be either "AMD_OPTERON" or "INTEL_XEON"')
      end
      raise('CPU family must be a string') unless value.is_a?(String)
    end
  end

  newproperty(:ram) do
    desc 'The amount of RAM in MB assigned to the server.'
    validate do |value|
      ram = begin
              Integer(value)
            rescue
              nil
            end
      raise('Server must have ram assigned') if value == ''
      raise('RAM must be a multiple of 256 MB') unless (ram % 256) == 0
    end
  end

  newproperty(:availability_zone) do
    desc 'The availability zone of where the server will reside.'
    defaultto 'AUTO'
    newvalues('AUTO', 'ZONE_1', 'ZONE_2')
  end

  newproperty(:boot_volume) do
    desc 'The boot volume name, if more than one volume it attached to the server.'

    validate do |value|
      raise ArgumentError, 'The volume type must be a String.' unless value.is_a?(String)
    end

    def insync?(is)
      is[:name] == should || is[:id] == should
    end
  end

  newproperty(:licence_type) do
    desc 'The OS type of the server.'
    newvalues('LINUX', 'WINDOWS', 'WINDOWS2016', 'UNKNOWN', 'OTHER')
  end

  newproperty(:nat) do
    desc 'A boolean which indicates if the NIC will perform Network Address Translation.'
    defaultto :false

    def insync?(_is)
      true
    end
  end

  newproperty(:volumes, array_matching: :all) do
    desc 'A list of volumes to associate with the server.'
    validate do |value|
      volumes = value.is_a?(Array) ? value : [value]
      volumes.each do |volume|
        next if volume.keys.include?('id')
        ['name', 'size', 'volume_type'].each do |key|
          raise("Volume must include #{key}") unless volume.keys.include?(key)
        end
      end
    end

    def insync?(is)
      PuppetX::IonoscloudX::Helper.objects_match(is, should, [:size])
    end
  end

  newproperty(:cdroms, array_matching: :all) do
    desc 'A list of Cdroms to associate with the server.'
    validate do |value|
      cdroms = value.is_a?(Array) ? value : [value]
      cdroms.each do |cdrom|
        raise("Cdrom must include 'id'") unless cdrom.keys.include?('id')
      end
    end

    def insync?(is)
      PuppetX::IonoscloudX::Helper.objects_match(is, should, [])
    end
  end

  newproperty(:purge_volumes) do
    desc 'Sets whether attached volumes are removed when server is removed.'
    defaultto :false
    newvalues(:true, :false)

    def insync?(_is)
      true
    end
  end

  newproperty(:nics, array_matching: :all) do
    desc 'A list of network interfaces associated with the server.'
    validate do |value|
      nics = value.is_a?(Array) ? value : [value]
      nics.each do |nic|
        ['name', 'dhcp', 'lan'].each do |key|
          raise("NIC must include #{key}") unless value.keys.include?(key)
        end
        if nic.key?('ips')
          raise('NIC "ips" must be an Array') unless nic['ips'].is_a?(Array)
        end
      end
    end

    def insync?(is)
      block = ->(existing_object, target_object) {
        PuppetX::IonoscloudX::Helper.objects_match(
          existing_object[:firewall_rules],
          target_object['firewall_rules'],
          [:source_mac, :source_ip, :target_ip, :port_range_start, :port_range_end, :icmp_type, :icmp_code],
        )
      }
      PuppetX::IonoscloudX::Helper.objects_match(is, should, [:firewall_active, :ips, :dhcp, :nat, :lan], &block)
    end
  end

  newproperty(:id) do
    desc 'The server ID.'

    def insync?(_is)
      true
    end
  end

  autorequire(:lan) do
    if self[:datacenter_id]
      self[:datacenter_id]
    else
      self[:datacenter_name]
    end
  end
end
