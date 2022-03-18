require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:networkloadbalancer).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    super(*args)
    @property_flush = {}
  end

  def self.instances
    PuppetX::IonoscloudX::Helper.datacenters_api.datacenters_get(depth: 1).items.map { |datacenter|
      networkloadbalancers = []
      # Ignore nat gateway if name is not defined.
      unless datacenter.properties.name.nil? || datacenter.properties.name.empty?
        PuppetX::IonoscloudX::Helper.networkloadbalancers_api.datacenters_networkloadbalancers_get(datacenter.id, depth: 5).items.map do |networkloadbalancer|
          next if networkloadbalancer.properties.name.nil? || networkloadbalancer.properties.name.empty?
          networkloadbalancers << new(instance_to_hash(networkloadbalancer, datacenter))
        end
      end
      networkloadbalancers
    }.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      next unless (resource = resources[prov.name])
      if resource[:datacenter_id] == prov.datacenter_id || resource[:datacenter_name] == prov.datacenter_name
        resource.provider = prov
      end
    end
  end

  def self.instance_to_hash(instance, datacenter)
    {
      id: instance.id,
      datacenter_id: datacenter.id,
      datacenter_name: datacenter.properties.name,

      name: instance.properties.name,
      ips: instance.properties.ips,
      listener_lan: instance.properties.listener_lan,
      target_lan: instance.properties.target_lan,
      lb_private_ips: instance.properties.lb_private_ips,

      rules: instance.entities.forwardingrules.items.map do |rule|
        {
          id: rule.id,
          name: rule.properties.name,
          algorithm: rule.properties.algorithm,
          protocol: rule.properties.protocol,
          listener_ip: rule.properties.listener_ip,
          listener_port: rule.properties.listener_port,
          health_check: {
            client_timeout: rule.properties.health_check.client_timeout,
            connect_timeout: rule.properties.health_check.connect_timeout,
            target_timeout: rule.properties.health_check.target_timeout,
            retries: rule.properties.health_check.retries,
          },
          targets: rule.properties.targets.map do |target|
            {
              ip: target.ip,
              port: target.port,
              weight: target.weight,
              health_check: {
                check: target.health_check.check,
                check_interval: target.health_check.check_interval,
                maintenance: target.health_check.maintenance,
              },
            }
          end,
        }.delete_if { |_k, v| v.nil? }
      end,
      flowlogs: instance.entities.flowlogs.items.map do |flowlog|
        {
          id: flowlog.id,
          name: flowlog.properties.name,
          action: flowlog.properties.action,
          direction: flowlog.properties.direction,
          bucket: flowlog.properties.bucket,
        }.delete_if { |_k, v| v.nil? }
      end,
      ensure: :present,
    }
  end

  def exists?
    Puppet.info("Checking if Network Load Balancer #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def ips=(value)
    @property_flush[:ips] = value
  end

  def listener_lan=(value)
    @property_flush[:listener_lan] = value
  end

  def target_lan=(value)
    @property_flush[:target_lan] = value
  end

  def lb_private_ips=(value)
    @property_flush[:lb_private_ips] = value
  end

  def flowlogs=(value)
    @property_flush[:flowlogs] = value
  end

  def rules=(value)
    @property_flush[:rules] = value
  end

  def create
    datacenter_id = PuppetX::IonoscloudX::Helper.resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])

    networkloadbalancer_properties = {
      name: resource[:name].to_s,
      ips: resource[:ips],
      lb_private_ips: resource[:lb_private_ips],
      listener_lan: resource[:listener_lan],
      target_lan: resource[:target_lan],
    }

    networkloadbalancer = Ionoscloud::NetworkLoadBalancer.new(
      properties: Ionoscloud::NetworkLoadBalancerProperties.new(**networkloadbalancer_properties),
      entities: Ionoscloud::NetworkLoadBalancerEntities.new(
        flowlogs: Ionoscloud::FlowLogs.new(
          items: PuppetX::IonoscloudX::Helper.flowlog_object_array_from_hashes(resource[:flowlogs]),
        ),
        forwardingrules: Ionoscloud::NetworkLoadBalancerForwardingRules.new(
          items: PuppetX::IonoscloudX::Helper.networkloadbalancer_rule_object_array_from_hashes(resource[:rules]),
        ),
      ),
    )
    networkloadbalancer, _, headers = PuppetX::IonoscloudX::Helper.networkloadbalancers_api.datacenters_networkloadbalancers_post_with_http_info(
      datacenter_id, networkloadbalancer
    )
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    Puppet.info("Created a new Network Load Balancer named #{resource[:name]}.")
    @property_hash[:ensure] = :present
    @property_hash[:datacenter_id] = datacenter_id
    @property_hash[:id] = networkloadbalancer.id
  end

  def destroy
    Puppet.info "Deleting Network Load Balancer #{@property_hash[:id]}"
    _, _, headers = PuppetX::IonoscloudX::Helper.networkloadbalancers_api.datacenters_networkloadbalancers_delete_with_http_info(
      @property_hash[:datacenter_id], @property_hash[:id]
    )
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:ensure] = :absent
  end

  def flush
    return if @property_flush.empty?

    entities_headers = PuppetX::IonoscloudX::Helper.sync_objects(
      @property_hash[:flowlogs], @property_flush[:flowlogs], [:networkloadbalancer, @property_hash[:datacenter_id], @property_hash[:id]],
      :update_flowlog, :create_flowlog, :delete_flowlog
    )

    entities_headers += PuppetX::IonoscloudX::Helper.sync_objects(
      @property_hash[:rules], @property_flush[:rules], [@property_hash[:datacenter_id], @property_hash[:id]],
      :update_networkloadbalancer_rule, :create_networkloadbalancer_rule, :delete_networkloadbalancer_rule
    )

    changeable_properties = [:ips, :lb_private_ips, :listener_lan, :target_lan]

    changes = Hash[*changeable_properties.flat_map { |v| [ v, @property_flush[v] ] } ].delete_if { |k, v| v.nil? || v == @property_hash[k] }

    changes[:ips] = @property_hash[:ips] if changes[:ips].nil?

    changes = Ionoscloud::NetworkLoadBalancerProperties.new(**changes)
    Puppet.info "Updating Network Load Balancer #{@property_hash[:name]} with #{changes}"

    _, _, headers = PuppetX::IonoscloudX::Helper.networkloadbalancers_api.datacenters_networkloadbalancers_patch_with_http_info(
      @property_hash[:datacenter_id], @property_hash[:id], changes
    )

    all_headers = entities_headers
    all_headers << headers

    all_headers.each { |headers| PuppetX::IonoscloudX::Helper.wait_request(headers) }

    changeable_properties.each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
    @property_flush = {}
  end
end
