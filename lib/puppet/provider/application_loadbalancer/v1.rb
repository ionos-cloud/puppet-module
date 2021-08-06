require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:application_loadbalancer).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    PuppetX::IonoscloudX::Helper.ionoscloud_config
    super(*args)
    @property_flush = {}
  end

  def self.instances
    PuppetX::IonoscloudX::Helper.ionoscloud_config
    Ionoscloud::DataCentersApi.new.datacenters_get(depth: 1).items.map { |datacenter|
      application_loadbalancers = []
      # Ignore nat gateway if name is not defined.
      unless datacenter.properties.name.nil? || datacenter.properties.name.empty?
        Ionoscloud::ApplicationLoadBalancersApi.new.datacenters_applicationloadbalancers_get(datacenter.id, depth: 5).items.map do |application_loadbalancer|
          next if application_loadbalancer.properties.name.nil? || application_loadbalancer.properties.name.empty?
          application_loadbalancers << new(instance_to_hash(application_loadbalancer, datacenter))
        end
      end
      application_loadbalancers
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
          protocol: rule.properties.protocol,
          listener_ip: rule.properties.listener_ip,
          listener_port: rule.properties.listener_port,
          health_check: {
            client_timeout: rule.properties.health_check.client_timeout,
          },
          server_certificates: rule.properties.server_certificates,
          http_rules: rule.properties.http_rules.nil? ? [] : rule.properties.http_rules.map do |http_rule|
            {
              name: http_rule.name,
              type: http_rule.type,
              target_group: http_rule.target_group,
              drop_query: http_rule.drop_query,
              location: http_rule.location,
              status_code: http_rule.status_code,
              response_message: http_rule.response_message,
              content_type: http_rule.content_type,
              conditions: http_rule.conditions.nil? ? [] : http_rule.conditions.map do |condition|
                {
                  type: condition.type,
                  condition: condition.condition,
                  negate: condition.negate,
                  key: condition.key,
                  value: condition.value,
                }
              end
            }
          end,
        }.delete_if { |_k, v| v.nil? }
      end,
      ensure: :present,
    }
  end

  def exists?
    Puppet.info("Checking if Application Load Balancer #{resource[:name]} exists.")
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

    applicationloadbalancer_properties = {
      name: resource[:name].to_s,
      ips: resource[:ips],
      listener_lan: resource[:listener_lan],
      target_lan: resource[:target_lan],
      lb_private_ips: resource[:lb_private_ips],
    }

    applicationloadbalancer = Ionoscloud::NetworkLoadBalancer.new(
      properties: Ionoscloud::NetworkLoadBalancerProperties.new(**applicationloadbalancer_properties),
      entities: Ionoscloud::NetworkLoadBalancerEntities.new(
        forwardingrules: Ionoscloud::NetworkLoadBalancerForwardingRules.new(
          items: PuppetX::IonoscloudX::Helper.applicationloadbalancer_rule_object_array_from_hashes(resource[:rules]),
        ),
      ),
    )
    applicationloadbalancer, _, headers = Ionoscloud::ApplicationLoadBalancersApi.new.datacenters_applicationloadbalancers_post_with_http_info(
      datacenter_id, applicationloadbalancer,
    )
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    Puppet.info("Created a new Application Load Balancer named #{resource[:name]}.")
    @property_hash[:ensure] = :present
    @property_hash[:datacenter_id] = datacenter_id
    @property_hash[:id] = applicationloadbalancer.id
  end

  def destroy
    Puppet.info "Deleting Application Load Balancer #{@property_hash[:id]}"
    _, _, headers = Ionoscloud::ApplicationLoadBalancersApi.new.datacenters_applicationloadbalancers_delete_with_http_info(
      @property_hash[:datacenter_id], @property_hash[:id],
    )
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:ensure] = :absent
  end

  def flush
    return if @property_flush.empty?

    entities_headers = PuppetX::IonoscloudX::Helper.sync_objects(
      @property_hash[:rules], @property_flush[:rules], [@property_hash[:datacenter_id], @property_hash[:id]],
      :update_application_loadbalancer_rule, :create_application_loadbalancer_rule, :delete_application_loadbalancer_rule
    )

    changeable_properties = [:ips, :lb_private_ips, :listener_lan, :target_lan]

    changes = Hash[*changeable_properties.flat_map { |v| [ v, @property_flush[v] ] } ].delete_if { |k, v| v.nil? || v == @property_hash[k] }

    changes[:ips] = @property_hash[:ips] if changes[:ips].nil?

    changes = Ionoscloud::NetworkLoadBalancerProperties.new(**changes)
    Puppet.info "Updating Application Load Balancer #{@property_hash[:name]} with #{changes}"

    _, _, headers = Ionoscloud::ApplicationLoadBalancersApi.new.datacenters_applicationloadbalancers_patch_with_http_info(
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
