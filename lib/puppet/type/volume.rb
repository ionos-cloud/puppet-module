Puppet::Type.newtype(:volume) do
  @doc = 'Type representing a IonosCloud storage volume.'
  @changeable_properties = [:size]
  @doc_directory = 'compute-engine'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the volume.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newparam(:image_password) do
    desc 'The image password for the "root" or "Administrator" account.'
    validate do |value|
      raise ArgumentError, 'The image password should be a String.' unless value.is_a?(String)
      if value.length < 8 || value.length > 50
        raise ArgumentError, 'The image password must contain at least 8 and no more than 50 characters.'
      end
      unless %r{^[0-9A-Za-z]+$}.match?(value)
        raise ArgumentError, 'Only [a-z][A-Z][0-9] characters are allowed for the image password.'
      end
    end
  end

  newparam(:ssh_keys, array_matching: :all) do
    desc 'One or more SSH keys to allow access to the volume via SSH.'
    validate do |value|
      raise ArgumentError, 'The SSH keys should be an Array.' unless value.is_a?(Array)
    end
  end

  newproperty(:size) do
    desc 'The size of the volume in GB.'
    validate do |value|
      raise ArgumentError, 'The size of the volume must be an integer.' unless value.is_a?(Integer)
    end
  end

  # read-only properties

  newproperty(:image_id) do
    desc 'The image or snapshot ID.'
    validate do |value|
      raise ArgumentError, 'The image ID should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:availability_zone) do
    desc 'The availability zone of where the volume will reside.'
    defaultto 'AUTO'

    validate do |value|
      raise ArgumentError, 'The availability zone should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:bus) do
    desc 'The bus type of the volume.'
    defaultto 'VIRTIO'
    newvalues('VIRTIO', 'IDE')

    validate do |value|
      raise ArgumentError, 'The bus type should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:volume_type) do
    desc 'The volume type.'
    defaultto 'HDD'
    newvalues('HDD')

    validate do |value|
      raise ArgumentError, 'The volume type should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:user_data) do
    desc 'The cloud-init configuration for the volume as base64 encoded string. '\
    'The property is immutable and is only allowed to be set on a new volume creation. '\
    'It is mandatory to provide either \'public image\' or \'imageAlias\' that has cloud-init '\
    'compatibility in conjunction with this property.'

    validate do |value|
      raise ArgumentError, 'The user data should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:licence_type) do
    desc 'The license type of the volume.'
    newvalues('LINUX', 'WINDOWS', 'WINDOWS2016', 'UNKNOWN', 'OTHER')

    validate do |value|
      raise ArgumentError, 'The license type should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

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

  newproperty(:backupunit_id) do
    desc 'The uuid of the Backup Unit that user has access to. The property is immutable and is '\
    'only allowed to be set on a new volume creation. It is mandatory to provide either \'public image\' '\
    'or \'imageAlias\' in conjunction with this property.'

    validate do |value|
      raise ArgumentError, 'The backupunit_id should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:cpu_hot_plug) do
    desc 'Indicates CPU hot plug capability.'

    def insync?(_is)
      true
    end
  end

  newproperty(:ram_hot_plug) do
    desc 'Indicates memory hot plug capability.'

    def insync?(_is)
      true
    end
  end

  newproperty(:nic_hot_plug) do
    desc 'Indicates NIC hot plug capability.'

    def insync?(_is)
      true
    end
  end

  newproperty(:nic_hot_unplug) do
    desc 'Indicates NIC hot unplug capability.'

    def insync?(_is)
      true
    end
  end

  newproperty(:disc_virtio_hot_plug) do
    desc 'Indicates VirtIO drive hot plug capability.'

    def insync?(_is)
      true
    end
  end

  newproperty(:disc_virtio_hot_unplug) do
    desc 'Indicates VirtIO drive hot unplug capability.'

    def insync?(_is)
      true
    end
  end

  newproperty(:datacenter_id) do
    desc 'The ID of the virtual data center where the volume will reside.'

    validate do |value|
      raise ArgumentError, 'The data center ID should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:datacenter_name) do
    desc 'The name of the virtual data center where the volume will reside.'

    validate do |value|
      raise ArgumentError, 'The data center name should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:id) do
    desc 'The volume ID.'

    def insync?(_is)
      true
    end
  end

  autorequire(:datacenter) do
    self[:datacenter_name]
  end
end
