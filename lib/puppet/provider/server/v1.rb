require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:server).provide(:v1) do
  confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    PuppetX::Profitbricks::Helper::profitbricks_config()
    super(*args)
  end

  def self.instances
    Ionoscloud::DataCenterApi.new.datacenters_get(depth: 1).items.map do |datacenter|
      servers = []
      # Ignore data center if name is not defined.
      unless datacenter.properties.name.nil? || datacenter.properties.name.empty?
        Ionoscloud::ServerApi.new.datacenters_servers_get(datacenter.id, depth: 3).items.each do |server|
          servers << new(instance_to_hash(server, datacenter))
        end
      end
      servers
    end.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        if resource[:datacenter_id] == prov.datacenter_id || resource[:datacenter_name] == prov.datacenter_name
          resource.provider = prov
        end
      end
    end
  end

  def self.instance_to_hash(instance, datacenter)
    volumes = instance.entities.volumes.items.map do |mapping|
      { name: mapping.properties.name }
    end

    nics = instance.entities.nics.items.map do |mapping|
      { name: mapping.properties.name }
    end

    instance_state = instance.properties.vm_state
    if ['SHUTOFF', 'SHUTDOWN', 'CRASHED'].include?(instance_state)
      state = :stopped
    else
      state = :present
    end

    boot_volume_name = ''
    unless instance.properties.boot_volume.nil?
      boot_volume_id = instance.properties.boot_volume.id
      instance.entities.volumes.items.map do |volume|
        boot_volume_name = volume.properties.name if volume.id == boot_volume_id
      end
    end

    config = {
      id: instance.id,
      datacenter_id: datacenter.id,
      datacenter_name: datacenter.properties.name,
      name: instance.properties.name,
      cores: instance.properties.cores,
      cpu_family: instance.properties.cpu_family,
      ram: instance.properties.ram,
      availability_zone: instance.properties.availability_zone,
      boot_volume: boot_volume_name,
      ensure: state,
      volumes: volumes,
      nics: nics,
    }
  end

  def cores=(value)
    server = PuppetX::Profitbricks::Helper::server_from_name(name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))

    Puppet.info("Updating server '#{name}', cores.")
    server.update(cores: value)
    server.wait_for { ready? }
  end

  def cpu_family=(value)
    server = PuppetX::Profitbricks::Helper::server_from_name(name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))

    Puppet.info("Updating server '#{name}', CPU family.")
    server.update(cpuFamily: value, allowReboot: true)
    server.wait_for { ready? }
  end

  def ram=(value)
    server = PuppetX::Profitbricks::Helper::server_from_name(name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))

    Puppet.info("Updating server '#{name}', RAM.")
    server.update(ram: value)
    server.wait_for { ready? }
  end

  def availability_zone=(value)
    server = PuppetX::Profitbricks::Helper::server_from_name(name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))

    Puppet.info("Updating server '#{name}', availability zone.")
    server.update(availabilityZone: value)
    server.wait_for { ready? }
  end

  def boot_volume=(value)
    server = PuppetX::Profitbricks::Helper::server_from_name(name,
      PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))

    volume = server.list_volumes.find { |volume| volume.properties['name'] == value }

    Puppet.info("Updating server '#{name}', boot volume.")
    server.update(bootVolume: { id: volume.id })
    server.wait_for { ready? }
  end

  def config_with_volumes(volumes)
    if volumes.nil?
      return []
    end

    volumes.map do |volume|
      config = {
        name: volume['name'],
        size: volume['size'],
        bus: volume['bus'],
        type: volume['volume_type'] || 'HDD',
        availability_zone: volume['availability_zone'],
      }

      if volume.key?('image_password')
        config[:image_password] = volume['image_password']
      elsif volume.key?('ssh_keys')
        config[:sshKeys] = volume['ssh_keys'].is_a?(Array) ? volume['ssh_keys'] : [volume['ssh_keys']]
      else
        fail('Volume must have either image_password or ssh_keys defined.')
      end

      if volume.key?('image_id')
        config[:image] = volume['image_id']
      elsif volume.key?('image_alias')
        config[:image_alias] = volume['image_alias']
      else
        fail('Volume must have either image_id or image_alias defined.')
      end

      Ionoscloud::Volume.new(
        properties: Ionoscloud::VolumeProperties.new(**config),
      )
    end
  end

  def config_with_fwrules(fwrules)
    if fwrules.nil?
      return []
    end

    fwrules.map do |fwrule|
      Ionoscloud::FirewallRule.new(
        properties: Ionoscloud::FirewallruleProperties.new(
          name: fwrule['name'],
          protocol: fwrule['protocol'],
          source_mac: fwrule['source_mac'],
          source_ip: fwrule['source_ip'],
          target_ip: fwrule['target_ip'],
          port_range_start: fwrule['port_range_start'],
          port_range_end: fwrule['port_range_end'],
          icmp_type: fwrule['icmp_type'],
          icmp_code: fwrule['icmp_code'],
        ),
      )
    end
  end

  def config_with_nics(nics)
    if nics.nil?
      return []
    end

    nics.map do |nic|
      lan = PuppetX::Profitbricks::Helper::lan_from_name(
        nic['lan'],
        PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]),
      )

      Ionoscloud::Nic.new(
        properties: Ionoscloud::NicProperties.new(
          name: nic['name'],
          ips: nic['ips'],
          dhcp: nic['dhcp'],
          lan: lan.id,
          nat: nic['nat']
        ),
        entities: Ionoscloud::NicEntities.new(
          firewallrules: Ionoscloud::FirewallRules.new(
            items: config_with_fwrules(nic['firewall_rules']),
          ),
        ),
      )
    end
  end

  def exists?
    Puppet.info("Checking if server #{name} exists")
    running? || stopped?
  end

  def running?
    Puppet.info("Checking if server #{name} is running")
    [:present, :pending, :running].include? @property_hash[:ensure]
  end

  def stopped?
    Puppet.info("Checking if server #{name} is stopped")
    [:stopping, :stopped].include? @property_hash[:ensure]
  end

  def create
    Puppet.info("Creating a new server called #{name}.")
    if stopped?
      restart
    else
      server = Ionoscloud::Server.new(
        properties: Ionoscloud::ServerProperties.new(
          name: resource[:name],
          cores: resource[:cores],
          cpu_family: resource[:cpu_family],
          ram: resource[:ram],
          availability_zone: resource[:availability_zone].to_s,
          boot_volume: resource[:boot_volume],
        ),
        entities: Ionoscloud::ServerEntities.new(
          volumes: Ionoscloud::Volumes.new(
            items: config_with_volumes(resource[:volumes]),
          ),
          nics: Ionoscloud::Nics.new(
            items: config_with_nics(resource[:nics]),
          ),
        ),
      )

      server, _, headers = Ionoscloud::ServerApi.new.datacenters_servers_post_with_http_info(
        PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]),
        server,
      )
      PuppetX::Profitbricks::Helper::wait_request(headers)

      Puppet.info("Server '#{name}' has been created.")
      @property_hash[:ensure] = :present

      @property_hash[:id] = server.id
    end
  end

  def restart
    Puppet.info("Restarting server #{name}")

    datacenter_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]).id
    _, _, headers = Ionoscloud::ServerApi.new.datacenters_servers_reboot_post_with_http_info(
      datacenter_id, PuppetX::Profitbricks::Helper::server_from_name(name, datacenter_id).id,
    )
    PuppetX::Profitbricks::Helper::wait_request(headers)
      
    @property_hash[:ensure] = :present
  end

  def stop
    create unless exists?
    Puppet.info("Stopping server #{name}")

    datacenter_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]).id
    _, _, headers = Ionoscloud::ServerApi.new.datacenters_servers_stop_post_with_http_info(
      datacenter_id, PuppetX::Profitbricks::Helper::server_from_name(name, datacenter_id).id,
    )
    PuppetX::Profitbricks::Helper::wait_request(headers)

    @property_hash[:ensure] = :stopped
  end

  def destroy
    puts 'distrugere'
    datacenter_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    server_id = PuppetX::Profitbricks::Helper::server_from_name(resource[:name], datacenter_id).id
    destroy_volumes(datacenter_id, server_id) if !resource[:purge_volumes].nil? && resource[:purge_volumes].to_s == 'true'

    Puppet.info("Deleting server #{name}.")

    _, _, headers = Ionoscloud::ServerApi.new.datacenters_servers_delete_with_http_info(datacenter_id, server_id)
    PuppetX::Profitbricks::Helper::wait_request(headers)

    @property_hash[:ensure] = :absent
  end

  def destroy_volumes(datacenter_id, server_id)
    headers_list = []

    Ionoscloud::ServerApi.new.datacenters_servers_volumes_get(
      datacenter_id,
      server_id,
      depth: 1,
    ).each do |volume|
      Puppet.info("Deleting volume #{volume.properties.name}")

      _, _, headers = Ionoscloud::VolumeApi.new.datacenters_volumes_delete_with_http_info(datacenter_id, volume.id)
      headers_list << headers
    end

    headers_list.each { |headers| PuppetX::Profitbricks::Helper::wait_request(headers) }
  end
end
