require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:natgateway).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    super(*args)
    @property_flush = {}
  end

  def self.instances
    Ionoscloud::DataCentersApi.new.datacenters_get(depth: 1).items.map { |datacenter|
      natgateways = []
      # Ignore nat gateway if name is not defined.
      unless datacenter.properties.name.nil? || datacenter.properties.name.empty?
        PuppetX::IonoscloudX::Helper.natgateways_api.datacenters_natgateways_get(datacenter.id, depth: 5).items.map do |natgateway|
          next if natgateway.properties.name.nil? || natgateway.properties.name.empty?
          natgateways << new(instance_to_hash(natgateway, datacenter))
        end
      end
      natgateways
    }.flatten
  end

  def self.prefetch(resources)
    resources.each_key do |key|
      resource = resources[key]
      next unless instances.count { |instance|
        instance.name == key &&
        (resource[:datacenter_id] == instance.datacenter_id || resource[:datacenter_name] == instance.datacenter_name)
      } > 1
      raise Puppet::Error, "Multiple #{resources[key].type} instances found for '#{key}'!"
    end
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
      public_ips: instance.properties.public_ips,
      lans: instance.properties.lans,
      rules: instance.entities.rules.items.map do |rule|
        {
          id: rule.id,
          name: rule.properties.name,
          protocol: rule.properties.protocol,
          public_ip: rule.properties.public_ip,
          source_subnet: rule.properties.source_subnet,
          target_subnet: rule.properties.target_subnet,
          target_port_range: if rule.properties.target_port_range.nil?
                               nil
                             else
                               {
                                 start: rule.properties.target_port_range.start,
                                         end: rule.properties.target_port_range._end,
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
      name: instance.properties.name,
      ensure: :present,
    }
  end

  def exists?
    Puppet.info("Checking if NAT Gateway #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def public_ips=(value)
    @property_flush[:public_ips] = value
  end

  def lans=(value)
    @property_flush[:lans] = value
  end

  def flowlogs=(value)
    @property_flush[:flowlogs] = value
  end

  def rules=(value)
    @property_flush[:rules] = value
  end

  def create
    datacenter_id = PuppetX::IonoscloudX::Helper.resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])

    natgateway_properties = {
      name: resource[:name].to_s,
      lans: resource[:lans],
      public_ips: resource[:public_ips],
    }

    natgateway = Ionoscloud::NatGateway.new(
      properties: Ionoscloud::NatGatewayProperties.new(**natgateway_properties),
      entities: Ionoscloud::NatGatewayEntities.new(
        flowlogs: Ionoscloud::FlowLogs.new(
          items: PuppetX::IonoscloudX::Helper.flowlog_object_array_from_hashes(resource[:flowlogs]),
        ),
        rules: Ionoscloud::NatGatewayRules.new(
          items: PuppetX::IonoscloudX::Helper.natgateway_rule_object_array_from_hashes(resource[:rules]),
        ),
      ),
    )
    natgateway, _, headers = PuppetX::IonoscloudX::Helper.natgateways_api.datacenters_natgateways_post_with_http_info(datacenter_id, natgateway)
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    Puppet.info("Created a new NAT Gateway named #{resource[:name]}.")
    @property_hash[:ensure] = :present
    @property_hash[:datacenter_id] = datacenter_id
    @property_hash[:id] = natgateway.id
  end

  def destroy
    Puppet.info "Deleting NAT Gateway #{@property_hash[:id]}"
    _, _, headers = PuppetX::IonoscloudX::Helper.natgateways_api.datacenters_natgateways_delete_with_http_info(
      @property_hash[:datacenter_id], @property_hash[:id]
    )
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:ensure] = :absent
  end

  def flush
    return if @property_flush.empty?

    entities_headers = PuppetX::IonoscloudX::Helper.sync_objects(
      @property_hash[:flowlogs], @property_flush[:flowlogs], [:natgateway, @property_hash[:datacenter_id], @property_hash[:id]],
      :update_flowlog, :create_flowlog, :delete_flowlog
    )

    entities_headers += PuppetX::IonoscloudX::Helper.sync_objects(
      @property_hash[:rules], @property_flush[:rules], [@property_hash[:datacenter_id], @property_hash[:id]],
      :update_natgateway_rule, :create_natgateway_rule, :delete_natgateway_rule
    )

    changes = Hash[*[:public_ips, :lans].flat_map { |v| [ v, @property_flush[v] ] } ].delete_if { |k, v| v.nil? || v == @property_hash[k] }

    changes = Ionoscloud::NatGatewayProperties.new(**changes)
    Puppet.info "Updating NAT Gateway #{@property_hash[:name]} with #{changes}"

    _, _, headers = PuppetX::IonoscloudX::Helper.natgateways_api.datacenters_natgateways_patch_with_http_info(@property_hash[:datacenter_id], @property_hash[:id], changes)

    all_headers = entities_headers
    all_headers << headers

    all_headers.each { |headers| PuppetX::IonoscloudX::Helper.wait_request(headers) }

    [:public_ips, :lans, :flowlogs].each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
    @property_flush = {}
  end
end
