require 'puppet/parameter/boolean'

Puppet::Type.newtype(:ionoscloud_group) do
  @doc = 'Type representing a IonosCloud group.'
  @changeable_properties = [
    :create_data_center, :create_snapshot, :reserve_ip, :access_activity_log, :s3_privilege,
    :create_backup_unit, :create_internet_access, :create_k8s_cluster, :create_pcc, :members
  ]

  ensurable

  newparam(:name, namevar: true) do
    desc 'The group name.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:create_data_center) do
    desc 'Indicates if the group is allowed to create virtual data centers.'
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:create_snapshot) do
    desc 'Indicates if the group is allowed to create snapshots.'
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:reserve_ip) do
    desc 'Indicates if the group is allowed to reserve IP addresses.'
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:access_activity_log) do
    desc 'Indicates if the group is allowed to access the activity log.'
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:s3_privilege) do
    desc 'Indicates if the group is allowed is allowed to manage S3.'
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:create_backup_unit) do
    desc 'Indicates if the group is allowed to manage backup units.'
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:create_internet_access) do
    desc 'Indicates if the group is allowed to create internet access.'
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:create_k8s_cluster) do
    desc 'Indicates if the group is allowed to create kubernetes cluster.'
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:create_pcc) do
    desc 'Indicates if the group is allowed to create pcc.'
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:members, array_matching: :all) do
    desc 'The ionoscloud users associated with the group.'

    def insync?(is)
      if is.is_a? Array
        is.sort == should.sort
      else
        is == should
      end
    end
  end

  # read-only properties

  newproperty(:id) do
    desc 'The group ID.'

    def insync?(_is)
      true
    end
  end
end
