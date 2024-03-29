require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:nic).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    super(*args)
    @property_flush = {}
  end

  def self.instances
    PuppetX::IonoscloudX::Helper.datacenters_api.datacenters_get(depth: 1).items.map { |datacenter|
      nics = []
      # Ignore data center if name is not defined.
      unless datacenter.properties.name.nil? || datacenter.properties.name.empty?
        lans = PuppetX::IonoscloudX::Helper.lans_api.datacenters_lans_get(datacenter.id, depth: 1).items

        unless lans.empty?
          PuppetX::IonoscloudX::Helper.servers_api.datacenters_servers_get(datacenter.id, depth: 5).items.map do |server|
            next if server.properties.name.nil? || server.properties.name.empty?
            server.entities.nics.items.map do |nic|
              unless nic.properties.name.nil? || nic.properties.name.empty?
                nics << new(instance_to_hash(nic, lans, server, datacenter))
              end
            end
          end
        end
      end
      nics
    }.flatten
  end

  def self.prefetch(resources)
    resources.each_key do |key|
      resource = resources[key]
      next unless instances.count { |instance|
        instance.name == key &&
        (resource[:datacenter_id] == instance.datacenter_id || resource[:datacenter_name] == instance.datacenter_name) &&
        (resource[:server_id] == instance.server_id || resource[:server_name] == instance.server_name)
      } > 1
      raise Puppet::Error, "Multiple #{resources[key].type} instances found for '#{key}'!"
    end
    instances.each do |prov|
      next unless (resource = resources[prov.name])
      if (resource[:datacenter_id] == prov.datacenter_id || resource[:datacenter_name] == prov.datacenter_name) &&
         (resource[:server_id] == prov.server_id || resource[:server_name] == prov.server_name)
        resource.provider = prov
      end
    end
  end

  def self.instance_to_hash(instance, lans, server, datacenter)
    lan = lans.find { |lan| lan.id == instance.properties.lan.to_s }
    {
      id: instance.id,
      datacenter_id: datacenter.id,
      datacenter_name: datacenter.properties.name,
      server_id: server.id,
      server_name: server.properties.name,
      lan: lan.properties.name,
      dhcp: instance.properties.dhcp,
      ips: instance.properties.ips,
      firewall_type: instance.properties.firewall_type,
      firewall_active: instance.properties.firewall_active,
      pci_slot: instance.properties.pci_slot,
      device_number: instance.properties.device_number,
      firewall_rules: instance.entities.firewallrules.items.map do |firewall_rule|
        {
          id: firewall_rule.id,
          name: firewall_rule.properties.name,
          type: firewall_rule.properties.type,
          source_mac: firewall_rule.properties.source_mac,
          source_ip: firewall_rule.properties.source_ip,
          target_ip: firewall_rule.properties.target_ip,
          port_range_start: firewall_rule.properties.port_range_start,
          port_range_end: firewall_rule.properties.port_range_end,
          icmp_type: firewall_rule.properties.icmp_type,
          icmp_code: firewall_rule.properties.icmp_code,
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
    Puppet.info("Checking if NIC #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def ips=(value)
    @property_flush[:ips] = value
  end

  def lan=(value)
    @property_flush[:lan] = value
  end

  def dhcp=(value)
    @property_flush[:dhcp] = value
  end

  def firewall_rules=(value)
    @property_flush[:firewall_rules] = value
  end

  def flowlogs=(value)
    @property_flush[:flowlogs] = value
  end

  def firewall_active=(value)
    @property_flush[:firewall_active] = value
  end

  def firewall_type=(value)
    @property_flush[:firewall_type] = value
  end

  def create
    datacenter_id = PuppetX::IonoscloudX::Helper.resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    server_id = resource[:server_id]
    unless server_id
      server_id = PuppetX::IonoscloudX::Helper.server_from_name(resource[:server_name], datacenter_id).id
    end

    nic, = PuppetX::IonoscloudX::Helper.create_nic(datacenter_id, server_id, resource, wait: true)

    Puppet.info("Created a new nic named #{resource[:name]}.")
    @property_hash[:ensure] = :present
    @property_hash[:datacenter_id] = datacenter_id
    @property_hash[:server_id] = server_id
    @property_hash[:id] = nic.id
  end

  def destroy
    PuppetX::IonoscloudX::Helper.delete_nic(@property_hash[:datacenter_id], @property_hash[:server_id], @property_hash[:id], wait: true)
    @property_hash[:ensure] = :absent
  end

  def flush
    return if @property_flush.empty?
    PuppetX::IonoscloudX::Helper.update_nic(
      @property_hash[:datacenter_id], @property_hash[:server_id], @property_hash[:id], @property_hash, JSON.parse(@property_flush.to_json), wait: true
    )

    [:firewall_active, :ips, :dhcp, :lan, :firewall_rules, :flowlogs].each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
    @property_flush = {}
  end
end
