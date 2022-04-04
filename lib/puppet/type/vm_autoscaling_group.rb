require 'puppet/parameter/boolean'

Puppet::Type.newtype(:vm_autoscaling_group) do
  @doc = 'Type representing a VM Autoscaling group.'
  @changeable_properties = [
    :description, :max_replica_count, :min_replica_count, :target_replica_count, :replica_configuration, :policy,
  ]
  @doc_directory = 'vm-autoscaling'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the VM Autoscaling group.'
    validate do |value|
      raise ArgumentError, 'The name should be a String.' unless value.is_a?(String)
    end
  end

  newproperty(:target_replica_count) do
    desc 'The target number of VMs in this Group. Depending on the scaling policy, this number will be adjusted automatically. '\
         'VMs will be created or destroyed automatically in order to adjust the actual number of VMs to this number. If '\
         'targetReplicaCount is given in the request body then it must be >= minReplicaCount and <= maxReplicaCount.'
    validate do |value|
      begin
        Integer(value)
      rescue
        raise('Target replica count must be a integer')
      end
    end
  end

  newproperty(:min_replica_count) do
    desc 'Minimum replica count value for `targetReplicaCount`. Will be enforced for both automatic and manual changes..'
    validate do |value|
      begin
        Integer(value)
      rescue
        raise('Minimum replica count must be a integer')
      end
    end
  end

  newproperty(:max_replica_count) do
    desc 'Maximum replica count value for `targetReplicaCount`. Will be enforced for both automatic and manual changes.'
    validate do |value|
      begin
        Integer(value)
      rescue
        raise('Maximum replica count must be a integer')
      end
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

  newproperty(:replica_configuration) do
    desc 'The replica configuration'

    validate do |value|
      unless value.is_a?(Hash)
        raise ArgumentError, 'The replica configuration should be a Hash.'
      end
    end

    def insync?(_is)
      PuppetX::IonoscloudX::Helper.compare_objects(is, should)
    end
  end

  newproperty(:policy) do
    desc 'Specifies the behavior of this autoscaling group. A policy consists of Triggers and Actions, '\
         'whereby an Action is some kind of automated behavior, and the Trigger defines the circumstances, '\
         'under which the Action is triggered. Currently, two separate Actions, namely Scaling In and Out are '\
         'supported, triggered through the thresholds, defined for a given Metric.'

    validate do |value|
      unless value.is_a?(Hash)
        raise ArgumentError, 'The policy should be a Hash.'
      end
    end

    def insync?(_is)
      PuppetX::IonoscloudX::Helper.compare_objects(is, should)
    end
  end

  newproperty(:location) do
    desc 'The data center location.'
    isrequired
    validate do |value|
      raise('Data center location must be set') if value == ''
      raise('Data center location must be a String') unless value.is_a?(String)
    end

    def insync?(_is)
      true
    end
  end

  # read-only properties

  newproperty(:id) do
    desc "The VM Autoscaling group's ID."

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
