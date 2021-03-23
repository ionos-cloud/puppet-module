require 'puppet_x/profitbricks/helper'

Puppet::Type.type(:server).provide(:v1) do
  confine feature: :profitbricks

  mk_resource_methods

  def initialize(*args)
    PuppetX::Profitbricks::Helper::profitbricks_config()
    super(*args)
    @property_flush = {}
  end

  def self.instances
    Ionoscloud::DataCenterApi.new.datacenters_get(depth: 1).items.map do |datacenter|
      servers = []
      # Ignore data center if name is not defined.
      unless datacenter.properties.name.nil? || datacenter.properties.name.empty?
        Ionoscloud::ServerApi.new.datacenters_servers_get(datacenter.id, depth: 5).items.each do |server|
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
    volumes = instance.entities.volumes.items.map do |volume|
      {
        id: volume.id,
        name: volume.properties.name,
        size: Integer(volume.properties.size),
      }
    end

    nics = instance.entities.nics.items.map do |nic|
      {
        id: nic.id,
        name: nic.properties.name,
        ips: nic.properties.ips,
        dhcp: nic.properties.dhcp,
        nat: nic.properties.nat,
        lan: nic.properties.lan,
        firewall_rules: nic.entities.firewallrules.items.map do
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
      }.delete_if { |_k, v| v.nil? }
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
    @property_flush[:cores] = value
  end

  def cpu_family=(value)
    @property_flush[:cpu_family] = value
  end

  def ram=(value)
    @property_flush[:ram] = value
  end

  def availability_zone=(value)
    @property_flush[:availability_zone] = value
  end

  def boot_volume=(value)
    @property_flush[:boot_volume] = value
  end

  def volumes=(value)
    existing_ids = @property_hash[:volumes].map { |volume| volume[:id] }
    existing_names = @property_hash[:volumes].map { |volume| volume[:name] }

    to_detach = existing_ids
    to_wait = []
    to_wait_create = []

    value.each do |desired_volume|
      if desired_volume['id']
        puts ['test', existing_ids].to_s
        if existing_ids.include? desired_volume['id']
          existing_volume = @property_hash[:volumes].find { |volume| volume[:id] == desired_volume['id'] }
          puts ['update', existing_volume, desired_volume].to_s
          headers =  PuppetX::Profitbricks::Helper::update_volume(
            @property_hash[:datacenter_id], existing_volume[:id], existing_volume, desired_volume,
          )
          
          to_wait << headers unless headers.nil?

          to_detach.delete(existing_volume[:id])
        else
          puts ['attach', @property_hash[:datacenter_id], @property_hash[:id], desired_volume['id']].to_s
          _, _, headers = Ionoscloud::ServerApi.new.datacenters_servers_volumes_post_with_http_info(
            @property_hash[:datacenter_id], @property_hash[:id], id: desired_volume['id'],
          )

          to_wait << headers
        end
      elsif desired_volume['name']
        puts ['test nume', existing_names].to_s
        if existing_names.include? desired_volume['name']
          existing_volume = @property_hash[:volumes].find { |volume| volume[:name] == desired_volume['name'] }

          puts ['update', existing_volume, desired_volume].to_s
          headers =  PuppetX::Profitbricks::Helper::update_volume(
            @property_hash[:datacenter_id], existing_volume[:id], existing_volume, desired_volume,
          )
          
          to_wait << headers unless headers.nil?

          to_detach.delete(existing_volume[:id])
        else
          puts ['create', desired_volume].to_s

          volume, _, headers = Ionoscloud::VolumeApi.new.datacenters_volumes_post_with_http_info(
            @property_hash[:datacenter_id], volume_object_from_hash(desired_volume),
          )

          to_wait_create << [ headers, volume.id ]
        end
      end
    end

    to_detach.each do |volume_id|
      puts ['detach', volume_id].to_s
      _, _, headers = Ionoscloud::ServerApi.new.datacenters_servers_volumes_delete_with_http_info(
        @property_hash[:datacenter_id], @property_hash[:id], volume_id,
      )
      to_wait << headers
    end

    to_wait_create.each do |headers, volume_id|
      puts ['attach', volume_id].to_s
      PuppetX::Profitbricks::Helper::wait_request(headers)
      _, _, new_headers = Ionoscloud::ServerApi.new.datacenters_servers_volumes_post_with_http_info(
        @property_hash[:datacenter_id], @property_hash[:id], id: volume_id,
      )

      to_wait << new_headers
    end

    to_wait.each { |headers| PuppetX::Profitbricks::Helper::wait_request(headers) }
  end

  def nics=(value)
    existing_names = @property_hash[:nics].map { |nic| nic[:name] }

    to_delete = @property_hash[:nics].map { |nic| nic[:id] }
    to_wait = []
    to_wait_create = []

    value.each do |desired_nic|
      if existing_names.include? desired_nic['name']
        existing_nic = @property_hash[:nics].find { |volume| volume[:name] == desired_nic['name'] }
        headers =  PuppetX::Profitbricks::Helper::update_nic(
          @property_hash[:datacenter_id], @property_hash[:id], existing_nic[:id], existing_nic, desired_nic,
        )
        
        to_wait += headers unless headers.empty?
        to_delete.delete(existing_nic[:id])
      else
        puts "Creating NIC #{desired_nic} in server #{@property_hash[:name]}"

        volume, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_post_with_http_info(
          @property_hash[:datacenter_id], @property_hash[:id], nic_object_from_hash(desired_nic),
        )
        to_wait << headers
      end
    end

    to_delete.each do |nic_id|
      puts "Deleting NIC #{nic_id} from server #{@property_hash[:name]}"
      _, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_delete_with_http_info(
        @property_hash[:datacenter_id], @property_hash[:id], nic_id,
      )
      to_wait << headers
    end

    to_wait.each { |headers| PuppetX::Profitbricks::Helper::wait_request(headers) }
  end

  def volume_object_from_hash(volume)
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

  def config_with_volumes(volumes)
    if volumes.nil?
      return []
    end

    volumes.map do |volume|
      if volume['id'].nil?
        volume_object_from_hash(volume)
      else
        Ionoscloud::Volume.new(
          id: volume['id'],
        )
      end

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

  def nic_object_from_hash(nic)
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
        nat: nic['nat'],
      ),
      entities: Ionoscloud::NicEntities.new(
        firewallrules: Ionoscloud::FirewallRules.new(
          items: config_with_fwrules(nic['firewall_rules']),
        ),
      ),
    )
  end

  def config_with_nics(nics)
    if nics.nil?
      return []
    end

    nics.map do |nic|
      nic_object_from_hash(nic)
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

  def flush
    changeable_properties = [:ram, :cpu_family, :cores, :availability_zone, :boot_volume]
    changes = Hash[ *changeable_properties.collect { |property| [ property, @property_flush[property] ] }.flatten ].delete_if { |_k, v| v.nil? }
    
    if !changes.empty?
      Puppet.info("Updating server '#{name}', #{changes.keys.to_s}.")
      datacenter_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
      server_id = PuppetX::Profitbricks::Helper::server_from_name(name, datacenter_id).id
      if changes[:boot_volume]
        volume = Ionoscloud::ServerApi.new.datacenters_servers_volumes_get(datacenter_id, server_id, depth: 1).items.find { |volume| volume.properties.name == changes[:boot_volume] }
        changes[:boot_volume] = { id: volume.id }
      end
      changes = Ionoscloud::ServerProperties.new(**changes)

      server, _, headers = Ionoscloud::ServerApi.new.datacenters_servers_patch_with_http_info(datacenter_id, server_id, changes)

      PuppetX::Profitbricks::Helper::wait_request(headers)
    end
  end

  def restart
    Puppet.info("Restarting server #{name}")

    datacenter_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    _, _, headers = Ionoscloud::ServerApi.new.datacenters_servers_reboot_post_with_http_info(
      datacenter_id, PuppetX::Profitbricks::Helper::server_from_name(name, datacenter_id).id,
    )
    PuppetX::Profitbricks::Helper::wait_request(headers)
      
    @property_hash[:ensure] = :present
  end

  def stop
    create unless exists?
    Puppet.info("Stopping server #{name}")

    datacenter_id = PuppetX::Profitbricks::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    _, _, headers = Ionoscloud::ServerApi.new.datacenters_servers_stop_post_with_http_info(
      datacenter_id, PuppetX::Profitbricks::Helper::server_from_name(name, datacenter_id).id,
    )
    PuppetX::Profitbricks::Helper::wait_request(headers)

    @property_hash[:ensure] = :stopped
  end

  def destroy
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
    ).items.each do |volume|
      Puppet.info("Deleting volume #{volume.properties.name}")

      _, _, headers = Ionoscloud::VolumeApi.new.datacenters_volumes_delete_with_http_info(datacenter_id, volume.id)
      headers_list << headers
    end

    headers_list.each { |headers| PuppetX::Profitbricks::Helper::wait_request(headers) }
  end
end
