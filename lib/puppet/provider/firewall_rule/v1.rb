require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:firewall_rule).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    super(*args)
    @property_flush = {}
  end

  def self.instances
    PuppetX::IonoscloudX::Helper.datacenters_api.datacenters_get(depth: 1).items.map { |datacenter|
      firewall_rules = []
      # Ignore data center if name is not defined.
      unless datacenter.properties.name.nil? || datacenter.properties.name.empty?
        PuppetX::IonoscloudX::Helper.servers_api.datacenters_servers_get(datacenter.id, depth: 5).items.map do |server|
          next if server.properties.name.nil? || server.properties.name.empty?
          server.entities.nics.items.map do |nic|
            next if nic.properties.name.nil? || nic.properties.name.empty?
            nic.entities.firewallrules.items.map do |firewall_rule|
              unless firewall_rule.properties.name.nil? || firewall_rule.properties.name.empty?
                firewall_rules << new(instance_to_hash(firewall_rule, nic, server, datacenter))
              end
            end
          end
        end
      end
      firewall_rules
    }.flatten
  end

  def self.prefetch(resources)
    resources.each_key do |key|
      resource = resources[key]
      next unless instances.count { |instance|
        instance.name == key &&
        (resource[:datacenter_id] == instance.datacenter_id || resource[:datacenter_name] == instance.datacenter_name) &&
        (resource[:server_id] == instance.server_id || resource[:server_name] == instance.server_name) &&
        (resource[:nic_id] == instance.nic_id || resource[:nic_name] == instance.nic_name)
      } > 1
      raise Puppet::Error, "Multiple #{resources[key].type} instances found for '#{key}'!"
    end

    instances.each do |prov|
      next unless (resource = resources[prov.name])
      next unless (resource[:datacenter_id] == prov.datacenter_id || resource[:datacenter_name] == prov.datacenter_name) &&
                  (resource[:server_id] == prov.server_id || resource[:server_name] == prov.server_name) &&
                  (resource[:nic_id] == prov.nic_id || resource[:nic_name] == prov.nic_name)
      resource.provider = prov
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
      nic_name: nic.properties.name,
      source_mac: firewall_rule.properties.source_mac,
      source_ip: firewall_rule.properties.source_ip,
      target_ip: firewall_rule.properties.target_ip,
      port_range_start: firewall_rule.properties.port_range_start,
      port_range_end: firewall_rule.properties.port_range_end,
      icmp_type: firewall_rule.properties.icmp_type,
      icmp_code: firewall_rule.properties.icmp_code,
      protocol: firewall_rule.properties.protocol,
      name: firewall_rule.properties.name,
      type: firewall_rule.properties.type,
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

  def type=(value)
    @property_flush[:type] = value
  end

  def create
    datacenter_id = PuppetX::IonoscloudX::Helper.resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    server_id = resource[:server_id] ? resource[:server_id] : PuppetX::IonoscloudX::Helper.server_from_name(resource[:server_name], datacenter_id).id
    nic = PuppetX::IonoscloudX::Helper.nics_api.datacenters_servers_nics_get(datacenter_id, server_id, depth: 1).items.find do |nic|
      nic.properties.name == resource[:nic_name]
    end

    raise "Nic named '#{resource[:nic_name]}' cannot be found." unless nic

    firewall_rule, = PuppetX::IonoscloudX::Helper.create_firewallrule(datacenter_id, server_id, nic.id, resource, wait: true)

    Puppet.info("Creating firewall rule '#{resource[:name]}'.")
    @property_hash[:ensure] = :present

    @property_hash[:datacenter_id] = datacenter_id
    @property_hash[:server_id] = server_id
    @property_hash[:nic_id] = nic.id
    @property_hash[:id] = firewall_rule.id
  end

  def destroy
    PuppetX::IonoscloudX::Helper.delete_firewallrule(
      @property_hash[:datacenter_id], @property_hash[:server_id], @property_hash[:nic_id], @property_hash[:id], wait: true
    )
    @property_hash[:ensure] = :absent
  end

  def flush
    return if @property_flush.empty?
    PuppetX::IonoscloudX::Helper.update_firewallrule(
      @property_hash[:datacenter_id], @property_hash[:server_id], @property_hash[:nic_id], @property_hash[:id],
      @property_hash, JSON.parse(@property_flush.to_json), wait: true
    )

    [:type, :source_mac, :source_ip, :target_ip, :port_range_start, :port_range_end, :icmp_type, :icmp_code].each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
  end
end
