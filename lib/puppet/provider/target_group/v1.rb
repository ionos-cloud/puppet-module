require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:target_group).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    super(*args)
    @property_flush = {}
  end

  def self.instances
    target_groups = []
    PuppetX::IonoscloudX::Helper.target_groups_api.targetgroups_get(depth: 1).items.each do |target_group|
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
      health_check: if instance.properties.health_check.nil?
                      {}
                    else
                      {
                        check_timeout: instance.properties.health_check.check_timeout,
                        check_interval: instance.properties.health_check.check_interval,
                        retries: instance.properties.health_check.retries,
                      }
                    end,
      http_health_check: if instance.properties.http_health_check.nil?
                           {}
                         else
                           {
                             path: instance.properties.http_health_check.path,
                              method: instance.properties.http_health_check.method,
                              match_type: instance.properties.http_health_check.match_type,
                              response: instance.properties.http_health_check.response,
                              regex: instance.properties.http_health_check.regex,
                              negate: instance.properties.http_health_check.negate,
                           }
                         end,

      targets: if instance.properties.targets.nil?
                 []
               else
                 instance.properties.targets.map do |target|
                   {
                     ip: target.ip,
                     port: target.port,
                     weight: target.weight,
                     health_check_enabled: target.health_check_enabled,
                     maintenance_enabled: target.maintenance_enabled,
                   }.delete_if { |_k, v| v.nil? }
                 end
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
      health_check: if resource[:health_check].nil?
                      nil
                    else
                      Ionoscloud::TargetGroupHealthCheck.new(
                            check_timeout: resource[:health_check]['check_timeout'],
                            check_interval: resource[:health_check]['check_interval'],
                            retries: resource[:health_check]['retries'],
                          )
                    end,
      http_health_check: if resource[:http_health_check].nil?
                           nil
                         else
                           Ionoscloud::TargetGroupHttpHealthCheck.new(
                                 path: resource[:http_health_check]['path'],
                                 method: resource[:http_health_check]['method'],
                                 match_type: resource[:http_health_check]['match_type'],
                                 response: resource[:http_health_check]['response'],
                                 regex: resource[:http_health_check]['regex'],
                                 negate: resource[:http_health_check]['negate'],
                               )
                         end,
      targets: if resource[:targets].nil?
                 nil
               else
                 resource[:targets].map do |target|
                   Ionoscloud::TargetGroupTarget.new(
                     ip: target['ip'],
                     port: target['port'],
                     weight: target['weight'],
                     health_check_enabled: target['health_check_enabled'],
                     maintenance_enabled: target['maintenance_enabled'],
                   )
                 end
               end,
    }

    target_group = Ionoscloud::TargetGroup.new(
      properties: Ionoscloud::TargetGroupProperties.new(**target_group_properties),
    )
    target_group, _, headers = PuppetX::IonoscloudX::Helper.target_groups_api.targetgroups_post_with_http_info(target_group)
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    Puppet.info("Created a new Target Group named #{resource[:name]}.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = target_group.id
  end

  def destroy
    Puppet.info "Deleting Target Group #{@property_hash[:id]}"
    _, _, headers = PuppetX::IonoscloudX::Helper.target_groups_api.target_groups_delete_with_http_info(@property_hash[:id])
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:ensure] = :absent
  end

  def flush
    return if @property_flush.empty?

    changeable_properties = [:algorithm, :protocol, :health_check, :http_health_check, :targets]

    changes = Hash[*changeable_properties.flat_map { |v| [ v, @property_flush[v] ] } ].delete_if do |k, v|
      v.nil? || PuppetX::IonoscloudX::Helper.compare_objects(@property_hash[k], v)
    end

    if changes[:health_check]
      changes[:health_check] = Ionoscloud::TargetGroupHealthCheck.new(
        check_timeout: changes[:health_check]['check_timeout'],
        check_interval: changes[:health_check]['check_interval'],
        retries: changes[:health_check]['retries'],
      )
    end

    if changes[:http_health_check]
      changes[:http_health_check] = Ionoscloud::TargetGroupHttpHealthCheck.new(
        path: changes[:http_health_check]['path'],
        method: changes[:http_health_check]['method'],
        match_type: changes[:http_health_check]['match_type'],
        response: changes[:http_health_check]['response'],
        regex: changes[:http_health_check]['regex'],
        negate: changes[:http_health_check]['negate'],
      )
    end

    if changes[:targets]
      changes[:targets] = changes[:targets].map do |target|
        Ionoscloud::TargetGroupTarget.new(
          ip: target['ip'],
          port: target['port'],
          weight: target['weight'],
          health_check_enabled: target['health_check_enabled'],
          maintenance_enabled: target['maintenance_enabled'],
        )
      end
    end

    changes = Ionoscloud::TargetGroupProperties.new(**changes)
    Puppet.info "Updating Target Group #{@property_hash[:name]} with #{changes}"

    _, _, headers = PuppetX::IonoscloudX::Helper.target_groups_api.targetgroups_patch_with_http_info(@property_hash[:id], changes)

    PuppetX::IonoscloudX::Helper.wait_request(headers)

    changeable_properties.each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
    @property_flush = {}
  end
end
