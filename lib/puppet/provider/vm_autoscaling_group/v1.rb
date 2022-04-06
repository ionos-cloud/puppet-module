require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:vm_autoscaling_group).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    super(*args)
    @property_flush = {}
  end

  def self.instances
    vm_autoscaling_groups = []
    PuppetX::IonoscloudX::Helper.vm_autoscaling_groups_api.autoscaling_groups_get(depth: 3).items.each do |group|
      vm_autoscaling_groups << new(instance_to_hash(group))
    end
    vm_autoscaling_groups.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:name] == prov.name
      end
    end
  end

  def self.instance_to_hash(instance)
    {
      id: instance.id,
      name: instance.properties.name,
      max_replica_count: instance.properties.max_replica_count,
      min_replica_count: instance.properties.min_replica_count,
      target_replica_count: instance.properties.target_replica_count,
      datacenter: instance.properties.datacenter.id,
      location: instance.properties.location,
      policy: PuppetX::IonoscloudX::Helper.deep_underscore_keys_in_object!(instance.properties.policy.to_hash),
      replica_configuration: PuppetX::IonoscloudX::Helper.deep_underscore_keys_in_object!(instance.properties.replica_configuration.to_hash),
      actions: instance.entities.actions.items.map do |action|
        {
          id: action.id,
          action_status: action.properties.action_status,
          action_type: action.properties.action_type,
          target_replica_count: action.properties.target_replica_count,
        }
      end,
      servers: instance.entities.servers.items.map do |server|
        {
          autoscaling_server_id: server.id,
          server_id: server.properties.datacenter_server.id,
        }
      end,
      ensure: :present,
    }
  end

  def target_replica_count=(value)
    @property_flush[:target_replica_count] = value
  end

  def min_replica_count=(value)
    @property_flush[:min_replica_count] = value
  end

  def max_replica_count=(value)
    @property_flush[:max_replica_count] = value
  end

  def replica_configuration=(value)
    @property_flush[:replica_configuration] = value
  end

  def policy=(value)
    @property_flush[:policy] = value
  end

  def exists?
    Puppet.info("Checking if the VM ASutoscaling group '#{name}' exists.")
    @property_hash[:ensure] == :present
  end

  def create
    datacenter_id = get_datacenter_id(resource[:datacenter])

    group = PuppetX::IonoscloudX::Helper.vm_autoscaling_groups_api.autoscaling_groups_post(
      IonoscloudVmAutoscaling::Group.new(properties: IonoscloudVmAutoscaling::GroupProperties.new(
        name: resource[:name],
        max_replica_count: resource[:max_replica_count],
        min_replica_count: resource[:min_replica_count],
        target_replica_count: resource[:target_replica_count],
        datacenter: { id: datacenter_id },
        location: resource[:location],
        policy: IonoscloudVmAutoscaling::GroupPolicy.new(
          metric: resource[:policy]['metric'],
          range: resource[:policy]['range'],
          scale_in_action: IonoscloudVmAutoscaling::GroupPolicyScaleInAction.new(
            amount: resource[:policy]['scale_in_action']['amount'],
            amount_type: resource[:policy]['scale_in_action']['amount_type'],
            cooldown_period: resource[:policy]['scale_in_action']['cooldown_period'],
            termination_policy: resource[:policy]['scale_in_action']['termination_policy'],
          ),
          scale_in_threshold: resource[:policy]['scale_in_threshold'],
          scale_out_action: IonoscloudVmAutoscaling::GroupPolicyScaleInAction.new(
            amount: resource[:policy]['scale_out_action']['amount'],
            amount_type: resource[:policy]['scale_out_action']['amount_type'],
            cooldown_period: resource[:policy]['scale_out_action']['cooldown_period'],
          ),
          scale_out_threshold: resource[:policy]['scale_out_threshold'],
          unit: resource[:policy]['unit'],
        ),
        replica_configuration: IonoscloudVmAutoscaling::ReplicaPropertiesPost.new(
          availability_zone: resource[:replica_configuration]['availability_zone'],
          cores: resource[:replica_configuration]['cores'],
          cpu_family: resource[:replica_configuration]['cpu_family'],
          ram: resource[:replica_configuration]['ram'],
          nics: resource[:replica_configuration]['nics'].map do |nic|
            begin
              IonoscloudVmAutoscaling::ReplicaNic.new(
                lan: Integer(nic['lan']),
                name: nic['name'],
                dhcp: nic['dhcp'],
              )
            rescue ArgumentError => e
              raise "LAN ID should be an Integer. Invalid value: #{nic['lan']}"
            end
          end,
          volumes: resource[:replica_configuration]['volumes'].map do |volume|
            IonoscloudVmAutoscaling::ReplicaVolumePost.new(
              image: volume['image'],
              name: volume['name'],
              size: volume['size'],
              ssh_keys: volume['ssh_keys'],
              type: volume['type'],
              user_data: volume['user_data'],
              bus: volume['bus'],
              image_password: volume['image_password'],
            )
          end,
        ),
      )),
    )

    Puppet.info("Created a new VM Autoscaling group '#{name}'.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = group.id
    @property_hash[:datacenter] = datacenter_id
    @property_hash[:name] = name
  end

  def flush
    return if @property_flush.empty?

    changeable_properties = [:target_replica_count, :min_replica_count, :max_replica_count, :replica_configuration, :policy]
    changes = Hash[ *changeable_properties.map { |property| [ property, @property_flush[property] ] }.flatten ].delete_if { |_k, v| v.nil? }

    return if changes.empty?

    Puppet.info("Updating VM Autoscaling group '#{name}', #{changes.keys}.")

    datacenter_id = get_datacenter_id(@property_hash[:datacenter])

    replica_configuration = PuppetX::IonoscloudX::Helper.deep_symbolize_keys_in_object!(@property_flush[:replica_configuration]) ||
                            @property_hash[:replica_configuration]
    policy = PuppetX::IonoscloudX::Helper.deep_symbolize_keys_in_object!(@property_flush[:policy]) || @property_hash[:policy]

    updated_group = IonoscloudVmAutoscaling::Group.new(properties: IonoscloudVmAutoscaling::GroupProperties.new(
      name: @property_hash[:name],
      datacenter: { id: @property_hash[:datacenter] },
      max_replica_count: @property_flush[:max_replica_count] || @property_hash[:max_replica_count],
      min_replica_count: @property_flush[:min_replica_count] || @property_hash[:min_replica_count],
      target_replica_count: @property_flush[:target_replica_count] || @property_hash[:target_replica_count],
      policy: IonoscloudVmAutoscaling::GroupPolicy.new(
        metric: policy[:metric],
        range: policy[:range],
        scale_in_action: IonoscloudVmAutoscaling::GroupPolicyScaleInAction.new(
          amount: policy[:scale_in_action][:amount],
          amount_type: policy[:scale_in_action][:amount_type],
          cooldown_period: policy[:scale_in_action][:cooldown_period],
          termination_policy: policy[:scale_in_action][:termination_policy],
        ),
        scale_in_threshold: policy[:scale_in_threshold],
        scale_out_action: IonoscloudVmAutoscaling::GroupPolicyScaleInAction.new(
          amount: policy[:scale_out_action][:amount],
          amount_type: policy[:scale_out_action][:amount_type],
          cooldown_period: policy[:scale_out_action][:cooldown_period],
        ),
        scale_out_threshold: policy[:scale_out_threshold],
        unit: policy[:unit],
      ),
      replica_configuration: IonoscloudVmAutoscaling::ReplicaProperties.new(
        availability_zone: replica_configuration[:availability_zone],
        cores: replica_configuration[:cores],
        cpu_family: replica_configuration[:cpu_family],
        ram: replica_configuration[:ram],
        nics: replica_configuration[:nics].map do |nic|
          begin
            IonoscloudVmAutoscaling::ReplicaNic.new(
              lan: nic[:lan],
              name: nic[:name],
              dhcp: nic[:dhcp],
            )
          rescue ArgumentError => e
            raise "LAN ID should be an Integer. Invalid value: #{nic[:lan]}"
          end
        end,
      ),
    ))

    PuppetX::IonoscloudX::Helper.vm_autoscaling_groups_api.autoscaling_groups_put(@property_hash[:id], updated_group)

    changeable_properties.each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
    @property_flush = {}
  end

  def destroy
    Puppet.info("Deleting VM ASutoscaling group '#{name}'...")
    PuppetX::IonoscloudX::Helper.vm_autoscaling_groups_api.autoscaling_groups_delete(@property_hash[:id])
    @property_hash[:ensure] = :absent
  end

  def get_datacenter_id(datacenter_id_or_name)
    return datacenter_id_or_name if PuppetX::IonoscloudX::Helper.validate_uuid_format(datacenter_id_or_name)
    PuppetX::IonoscloudX::Helper.resolve_datacenter_id(nil, datacenter_id_or_name)
  end
end
