require 'puppet/parameter/boolean'

Puppet::Type.newtype(:snapshot) do
  @doc = 'Type representing a IonosCloud Snapshot.'
  @changeable_properties = [
    :description, :cpu_hot_plug, :cpu_hot_unplug, :ram_hot_plug, :ram_hot_unplug, :nic_hot_plug, :nic_hot_unplug, :disc_virtio_hot_plug,
    :disc_virtio_hot_unplug, :disc_scsi_hot_plug, :disc_scsi_hot_unplug, :sec_auth_protection, :licence_type
  ]
  @doc_directory = 'compute-engine'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the snapshot.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:restore) do
    desc 'If true, restore the snapshot onto the volume specified be the volume property.'
    newvalues(:true, :false)
    def insync?(_is)
      should.to_s != 'true'
    end
  end

  newproperty(:datacenter) do
    desc 'The ID or name of the virtual data center where the volume resides.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, 'The data center ID/name should be a String.'
      end
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:volume) do
    desc 'The ID or name of the volume used to create/restore the snapshot.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, 'The volume ID/name should be a String.'
      end
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:description) do
    desc "The snapshot's description."
  end

  newproperty(:sec_auth_protection) do
    desc 'Flag representing if extra protection is enabled on snapshot e.g. Two Factor protection etc.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:licence_type) do
    desc 'The OS type of this Snapshot'
    newvalues('LINUX', 'WINDOWS', 'WINDOWS2016', 'UNKNOWN', 'OTHER')

    validate do |value|
      raise ArgumentError, 'The license type should be a String.' unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  newproperty(:cpu_hot_plug) do
    desc 'Indicates CPU hot plug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:cpu_hot_unplug) do
    desc 'Indicates CPU hot unplug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:ram_hot_plug) do
    desc 'Indicates memory hot plug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:ram_hot_unplug) do
    desc 'Indicates memory hot unplug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:nic_hot_plug) do
    desc 'Indicates NIC hot plug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:nic_hot_unplug) do
    desc 'Indicates NIC hot unplug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:disc_virtio_hot_plug) do
    desc 'Indicates VirtIO drive hot plug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:disc_virtio_hot_unplug) do
    desc 'Indicates VirtIO drive hot unplug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:disc_scsi_hot_plug) do
    desc 'Indicates SCSI drive hot plug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:disc_scsi_hot_unplug) do
    desc 'Indicates SCSI drive hot unplug capability.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  # read-only properties

  newproperty(:id) do
    desc "The snapshot's ID."

    def insync?(_is)
      true
    end
  end

  newproperty(:location) do
    desc "The snapshot's location."

    def insync?(_is)
      true
    end
  end

  newproperty(:size) do
    desc 'The size of the snapshot in GB.'

    def insync?(_is)
      true
    end
  end

  autorequire(:datacenter) do
    self[:datacenter]
  end
  autorequire(:volume) do
    self[:volume]
  end
end
