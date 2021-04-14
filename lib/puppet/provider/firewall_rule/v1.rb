require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:firewall_rule).provide(:v1) do
  # confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    self.class.client
    super(*args)
    @property_flush = {}
  end

  def self.client
    PuppetX::Profitbricks::Helper::profitbricks_config
  end

  def self.instances
    PuppetX::Profitbricks::Helper::profitbricks_config

    Ionoscloud::DataCenterApi.new.datacenters_get(depth: 1).items.map do |datacenter|
      firewall_rules = []
      # Ignore data center if name is not defined.
      unless datacenter.properties.name.nil? || datacenter.properties.name.empty?
        Ionoscloud::ServerApi.new.datacenters_servers_get(datacenter.id, depth: 5).items.map do |server|
          unless server.properties.name.nil? || server.properties.name.empty?
            server.entities.nics.items.map do |nic|
              unless nic.properties.name.nil? || nic.properties.name.empty?
                nic.entities.firewallrules.items.map do |firewall_rule|
                  unless firewall_rule.properties.name.nil? || firewall_rule.properties.name.empty?
                    firewall_rules << new(instance_to_hash(firewall_rule, nic, server, datacenter))
                  end
                end
              end
            end
          end
        end
      end
      firewall_rules
    end.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        if (resource[:datacenter_id] == prov.datacenter_id || resource[:datacenter_name] == prov.datacenter_name) &&
           (resource[:server_id] == prov.server_id || resource[:server_name] == prov.server_name) &&
           resource[:nic] == prov.nic
          resource.provider = prov
        end
      end
    end
  end

  def self.instance_to_hash(firewall_rule, nic, server, datacenter)
    {
      id: firewall_rule.id,
      datacenter_id: datacenter.id,
      datacenter_name: datacenter.properties.name,
      server_id: server.id,
      server_name: server.properties.name,
      nic_id: nic.id,
      nic: nic.properties.name,
      source_mac: firewall_rule.properties.source_mac,
      source_ip: firewall_rule.properties.source_ip,
      target_ip: firewall_rule.properties.target_ip,
      port_range_start: firewall_rule.properties.port_range_start,
      port_range_end: firewall_rule.properties.port_range_end,
      icmp_type: firewall_rule.properties.icmp_type,
      icmp_code: firewall_rule.properties.icmp_code,
      protocol: firewall_rule.properties.protocol,
      name: firewall_rule.properties.name,
      ensure: :present,
    }
  end

  def exists?
    Puppet.info("Checking if firewall rule #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def icmp_code=(value)
    @property_flush[:icmp_code] = value
  end

  def icmp_type=(value)
    @property_flush[:icmp_type] = value
  end

  def port_range_start=(value)
    @property_flush[:port_range_start] = value
  end

  def port_range_end=(value)
    @property_flush[:port_range_end] = value
  end

  def source_mac=(value)
    @property_flush[:source_mac] = value
  end

  def source_ip=(value)
    @property_flush[:source_ip] = value
  end

  def target_ip=(value)
    @property_flush[:target_ip] = value
  end

  def create
    firewall_rule = PuppetX::Profitbricks::Helper::firewallrule_object_from_hash(resource)
    datacenter_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    server_id = resource[:server_id] ? resource[:server_id] : PuppetX::Profitbricks::Helper::server_from_name(resource[:server_name], datacenter_id).id
    nic = Ionoscloud::NicApi.new.datacenters_servers_nics_get(datacenter_id, server_id, depth: 1).items.find { |nic| nic.properties.name == resource[:nic] }

    fail "Nic named '#{resource[:nic]}' cannot be found." unless nic

    firewall_rule, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_firewallrules_post_with_http_info(
      datacenter_id, server_id, nic.id, firewall_rule,
    )
    PuppetX::Profitbricks::Helper::wait_request(headers)

    Puppet.info("Creating firewall rule '#{resource[:name]}'.")
    @property_hash[:ensure] = :present

    @property_hash[:datacenter_id] = datacenter_id 
    @property_hash[:server_id] = server_id 
    @property_hash[:nic_id] = nic.id 
    @property_hash[:id] = firewall_rule.id
  end

  def destroy
    Puppet.info("Deleting firewall rule #{name}.")
    
    _, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_firewallrules_delete_with_http_info(
      @property_hash[:datacenter_id], @property_hash[:server_id], @property_hash[:nic_id], @property_hash[:id],
    )
    PuppetX::Profitbricks::Helper::wait_request(headers)

    @property_hash[:ensure] = :absent
  end

  def flush
    PuppetX::Profitbricks::Helper::update_firewallrule(
      @property_hash[:datacenter_id], @property_hash[:server_id],@property_hash[:nic_id], @property_hash[:id], @property_hash, @property_flush.transform_keys(&:to_s), wait: true,
    )

    [:source_mac, :source_ip, :target_ip, :port_range_start, :port_range_end, :icmp_type, :icmp_code].each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
  end
end
