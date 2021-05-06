require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:nic).provide(:v1) do
  # confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    PuppetX::Profitbricks::Helper::profitbricks_config
    super(*args)
    @property_flush = {}
  end
  
  def self.instances
    Ionoscloud::DataCenterApi.new.datacenters_get(depth: 1).items.map do |datacenter|
      nics = []
      # Ignore data center if name is not defined.
      unless datacenter.properties.name.nil? || datacenter.properties.name.empty?
        lans = Ionoscloud::LanApi.new.datacenters_lans_get(datacenter.id, depth: 1).items


        unless lans.empty?
          Ionoscloud::ServerApi.new.datacenters_servers_get(datacenter.id, depth: 5).items.map do |server|
            unless server.properties.name.nil? || server.properties.name.empty?
              server.entities.nics.items.map do |nic|
                unless nic.properties.name.nil? || nic.properties.name.empty?
                  nics << new(instance_to_hash(nic, lans, server, datacenter))
                end
              end
            end
          end
        end
      end
      nics
    end.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        if (resource[:datacenter_id] == prov.datacenter_id || resource[:datacenter_name] == prov.datacenter_name) &&
           (resource[:server_id] == prov.server_id || resource[:server_name] == prov.server_name)
          resource.provider = prov
        end
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
      nat: instance.properties.nat,
      ips: instance.properties.ips,
      firewall_active: instance.properties.firewall_active,
      firewall_rules: instance.entities.firewallrules.items.map do
        |firewall_rule|
        {
          id: firewall_rule.id,
          name: firewall_rule.properties.name,
          source_mac: firewall_rule.properties.source_mac,
          source_ip: firewall_rule.properties.source_ip,
          target_ip: firewall_rule.properties.target_ip,
          port_range_start: firewall_rule.properties.port_range_start,
          port_range_end: firewall_rule.properties.port_range_end,
          icmp_type: firewall_rule.properties.icmp_type,
          icmp_code: firewall_rule.properties.icmp_code,
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

  def nat=(value)
    @property_flush[:nat] = value
  end

  def dhcp=(value)
    @property_flush[:dhcp] = value
  end

  def firewall_rules=(value)
    @property_flush[:firewall_rules] = value
  end

  def create
    datacenter_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    server_id = resource[:server_id]
    unless server_id
      server_id = PuppetX::Profitbricks::Helper::server_from_name(resource[:server_name], datacenter_id).id
    end

    nic = PuppetX::Profitbricks::Helper::nic_object_from_hash(resource, datacenter_id)

    Puppet.info "Creating a new NIC #{nic.to_hash}."

    nic, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_post_with_http_info(datacenter_id, server_id, nic)
    PuppetX::Profitbricks::Helper::wait_request(headers)

    Puppet.info("Created a new nic named #{resource[:name]}.")
    @property_hash[:ensure] = :present
    @property_hash[:datacenter_id] = datacenter_id
    @property_hash[:server_id] = server_id
    @property_hash[:id] = nic.id
  end

  def destroy
    _, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_delete_with_http_info(
      @property_hash[:datacenter_id], @property_hash[:server_id], @property_hash[:id],
    )
    PuppetX::Profitbricks::Helper::wait_request(headers)
    @property_hash[:ensure] = :absent
  end

  def flush
    PuppetX::Profitbricks::Helper::update_nic(
      @property_hash[:datacenter_id], @property_hash[:server_id], @property_hash[:id], @property_hash, @property_flush.transform_keys(&:to_s), wait: true,
    )

    [:firewall_active, :ips, :dhcp, :nat, :lan, :firewall_rules].each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
  end
end
