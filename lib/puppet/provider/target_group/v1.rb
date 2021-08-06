require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:target_group).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    PuppetX::IonoscloudX::Helper.ionoscloud_config
    super(*args)
    @property_flush = {}
  end

  def self.instances
    PuppetX::IonoscloudX::Helper.ionoscloud_config
    target_groups = []
    Ionoscloud::TargetGroupsApi.new.targetgroups_get(depth: 1).items.each do |target_group|
      # Ignore target groups if name is not defined.
      target_groups << new(instance_to_hash(target_group)) unless target_group.properties.name.nil? || target_group.properties.name.empty?
    end
    target_groups.flatten
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
      algorithm: instance.properties.algorithm,
      protocol: instance.properties.protocol,
      health_check: {
        check_timeout: instance.properties.health_check.check_timeout,
        connect_timeout: instance.properties.health_check.connect_timeout,
        target_timeout: instance.properties.health_check.target_timeout,
        retries: instance.properties.health_check.retries,
      },
      http_health_check: {
        path: instance.properties.http_health_check.path,
        method: instance.properties.http_health_check.method,
        match_type: instance.properties.http_health_check.match_type,
        response: instance.properties.http_health_check.response,
        regex: instance.properties.http_health_check.regex,
        negate: instance.properties.http_health_check.negate,
      },

      targets: instance.properties.targets.map do |target|
        {
          ip: target.ip,
          port: target.port,
          weight: target.weight,
          health_check: {
            check: target.health_check.check,
            check_interval: target.health_check.check_interval,
            maintenance: target.health_check.maintenance,
          },
        }.delete_if { |_k, v| v.nil? }
      end,
      ensure: :present,
    }
  end

  def exists?
    Puppet.info("Checking if Target Group #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def algorithm=(value)
    @property_flush[:algorithm] = value
  end

  def protocol=(value)
    @property_flush[:protocol] = value
  end

  def health_check=(value)
    @property_flush[:health_check] = value
  end

  def http_health_check=(value)
    @property_flush[:http_health_check] = value
  end

  def targets=(value)
    @property_flush[:targets] = value
  end

  def create
    target_group_properties = {
      name: resource[:name].to_s,
      algorithm: resource[:algorithm],
      protocol: resource[:protocol],
      health_check: resource[:health_check].nil? ? nil : Ionoscloud::TargetGroupHealthCheck.new(
        check_timeout: resource[:health_check]['check_timeout'],
        connect_timeout: resource[:health_check]['connect_timeout'],
        target_timeout: resource[:health_check]['target_timeout'],
        retries: resource[:health_check]['retries'],
      ),
      http_health_check: resource[:http_health_check].nil? ? nil : Ionoscloud::TargetGroupHttpHealthCheck.new(
        path: resource[:http_health_check]['path'],
        method: resource[:http_health_check]['method'],
        match_type: resource[:http_health_check]['match_type'],
        response: resource[:http_health_check]['response'],
        regex: resource[:http_health_check]['regex'],
        negate: resource[:http_health_check]['negate'],
      ),
      targets: resource[:targets].nil? ? nil : resource[:targets].map do
        |target|
        Ionoscloud::TargetGroupTarget.new(
          ip: target['ip'],
          port: target['port'],
          weight: target['weight'],
          health_check: target['health_check'].nil? ? nil : Ionoscloud::TargetGroupTargetHealthCheck.new(
            check: target['health_check']['check'],
            check_interval: target['health_check']['check_interval'],
            maintenance: target['health_check']['maintenance'],
          ),
        )
      end,
    }

    target_group = Ionoscloud::TargetGroup.new(
      properties: Ionoscloud::TargetGroupProperties.new(**target_group_properties),
    )
    target_group, _, headers = Ionoscloud::TargetGroupsApi.new.targetgroups_post_with_http_info(target_group)
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    Puppet.info("Created a new Target Group named #{resource[:name]}.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = target_group.id
  end

  def destroy
    Puppet.info "Deleting Target Group #{@property_hash[:id]}"
    _, _, headers = Ionoscloud::TargetGroupsApi.new.target_groups_delete_with_http_info(@property_hash[:id])
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:ensure] = :absent
  end

  def flush
    return if @property_flush.empty?

    changeable_properties = [:algorithm, :protocol, :health_check, :http_health_check, :targets]

    changes = Hash[*changeable_properties.flat_map { |v| [ v, @property_flush[v] ] } ].delete_if do
      |k, v|
      v.nil? || PuppetX::IonoscloudX::Helper.compare_objects(@property_hash[k], v)
    end

    changes[:health_check] = Ionoscloud::TargetGroupHealthCheck.new(
      check_timeout: changes[:health_check]['check_timeout'],
      connect_timeout: changes[:health_check]['connect_timeout'],
      target_timeout: changes[:health_check]['target_timeout'],
      retries: changes[:health_check]['retries'],
    ) if changes[:health_check]

    changes[:http_health_check] = Ionoscloud::TargetGroupHttpHealthCheck.new(
      path: changes[:http_health_check]['path'],
      method: changes[:http_health_check]['method'],
      match_type: changes[:http_health_check]['match_type'],
      response: changes[:http_health_check]['response'],
      regex: changes[:http_health_check]['regex'],
      negate: changes[:http_health_check]['negate'],
    ) if changes[:http_health_check]

    changes[:targets] = changes[:targets].map do
      |target|
      Ionoscloud::TargetGroupTarget.new(
        ip: target['ip'],
        port: target['port'],
        weight: target['weight'],
        health_check: target['health_check'].nil? ? nil : Ionoscloud::TargetGroupTargetHealthCheck.new(
          check: target['health_check']['check'],
          check_interval: target['health_check']['check_interval'],
          maintenance: target['health_check']['maintenance'],
        ),
      )
    end if changes[:targets]

    changes = Ionoscloud::TargetGroupProperties.new(**changes)
    Puppet.info "Updating Target Group #{@property_hash[:name]} with #{changes}"

    _, _, headers = Ionoscloud::TargetGroupsApi.new.targetgroups_patch_with_http_info(@property_hash[:id], changes)
    
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    changeable_properties.each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
    @property_flush = {}
  end
end
