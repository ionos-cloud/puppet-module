require 'puppet/parameter/boolean'

Puppet::Type.newtype(:share) do
  @doc = 'Type representing a IonosCloud shared resource.'
  @changeable_properties = [:edit_privilege, :share_privilege]
  @doc_directory = 'user'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The ID of the resource to share.'
    validate do |value|
      raise('The ID should be a String') unless value.is_a?(String)
    end
  end

  newproperty(:edit_privilege) do
    desc 'Indicates if the group has permission to edit privileges on the resource.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:share_privilege) do
    desc 'Indicates if the group has permission to share the resource.'
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:group_id) do
    desc 'The ID of the group where the share will be available.'

    def insync?(_is)
      true
    end
  end

  newproperty(:group_name) do
    desc 'The name of the group where the share will be available.'

    def insync?(_is)
      true
    end
  end

  # read-only properties

  newproperty(:type) do
    desc 'The type of the shared resource.'

    def insync?(_is)
      true
    end
  end

  autorequire(:ionoscloud_group) do
    self[:group_name]
  end
end
