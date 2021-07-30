require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:server).provide(:v1) do
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
      servers = []
      # Ignore data center if name is not defined.
      unless datacenter.properties.name.nil? || datacenter.properties.name.empty?
        Ionoscloud::ServersApi.new.datacenters_servers_get(datacenter.id, depth: 5).items.each do |server|
          servers << new(instance_to_hash(server, datacenter))
        end
      end
      servers
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
    volumes = instance.entities.volumes.items.map do |volume|
      {
        id: volume.id,
        name: volume.properties.name,
        size: Integer(volume.properties.size),
      }
    end

    cdroms = instance.entities.cdroms.items.map do |cdrom|
      {
        id: cdrom.id,
        name: cdrom.properties.name,
        size: Float(cdrom.properties.size),
      }
    end

    nics = instance.entities.nics.items.map do |nic|
      lan = Ionoscloud::LansApi.new.datacenters_lans_find_by_id(datacenter.id, nic.properties.lan)
      {
        id: nic.id,
        name: nic.properties.name,
        ips: nic.properties.ips,
        dhcp: nic.properties.dhcp,
        lan: lan.properties.name,
        firewall_active: nic.properties.firewall_active,
        firewall_type: nic.properties.firewall_type,
        firewall_rules: nic.entities.firewallrules.items.map do |firewall_rule|
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
        flowlogs: nic.entities.flowlogs.items.map do |flowlog|
          {
            id: flowlog.id,
            name: flowlog.properties.name,
            action: flowlog.properties.action,
            direction: flowlog.properties.direction,
            bucket: flowlog.properties.bucket,
          }.delete_if { |_k, v| v.nil? }
        end,
      }.delete_if { |_k, v| v.nil? }
    end

    instance_state = instance.properties.vm_state
    state = if ['SHUTOFF', 'SHUTDOWN', 'CRASHED'].include?(instance_state)
              :stopped
            elsif ['SUSPENDED'].include?(instance_state)
              :suspended
            else
              :present
            end

    boot_volume_name = boot_volume_id = ''
    unless instance.properties.boot_volume.nil?
      boot_volume_id = instance.properties.boot_volume.id
      instance.entities.volumes.items.map do |volume|
        boot_volume_name = volume.properties.name if volume.id == boot_volume_id
      end
    end

    {
      id: instance.id,
      datacenter_id: datacenter.id,
      datacenter_name: datacenter.properties.name,
      name: instance.properties.name,
      type: instance.properties.type,
      template_uuid: instance.properties.template_uuid,
      cores: instance.properties.cores,
      cpu_family: instance.properties.cpu_family,
      ram: instance.properties.ram,
      availability_zone: instance.properties.availability_zone,
      boot_volume: {
        id: boot_volume_id,
        name: boot_volume_name,
      },
      ensure: state,
      volumes: volumes,
      cdroms: cdroms,
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
    if !PuppetX::IonoscloudX::Helper.validate_uuid_format(resource[:boot_volume].to_s)
      volume = Ionoscloud::ServersApi.new.datacenters_servers_volumes_get(
        @property_hash[:datacenter_id], @property_hash[:id], depth: 1
      ).items.find { |volume| volume.properties.name == value }
      raise "Volume #{value} not found" unless volume
      @property_flush[:boot_volume] = { id: volume.id }
    else
      @property_flush[:boot_volume] = { id: value }
    end
  end

  def cdroms=(value)
    PuppetX::IonoscloudX::Helper.sync_objects(
      @property_hash[:cdroms], value, [@property_hash[:datacenter_id], @property_hash[:id]],
      :update_cdrom, :attach_cdrom, :detach_cdrom, wait: true, id_field: :id
    )

    @property_hash[:cdrom] = value
  end

  def volumes=(value)
    PuppetX::IonoscloudX::Helper.sync_volumes(
      @property_hash[:datacenter_id], @property_hash[:id], @property_hash[:volumes], value, wait: true
    )
    @property_hash[:volumes] = value
  end

  def nics=(value)
    PuppetX::IonoscloudX::Helper.sync_objects(
      @property_hash[:nics], value, [@property_hash[:datacenter_id], @property_hash[:id]],
      :update_nic, :create_nic, :delete_nic, wait: true
    )
    @property_hash[:nics] = value
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

  def suspended?
    Puppet.info("Checking if server #{name} is suspended")
    [:suspended].include? @property_hash[:ensure]
  end

  def create
    Puppet.info("Creating a new server called #{name}.")
    if stopped?
      restart
    elsif suspended?
      resume
    else
      datacenter_id = PuppetX::IonoscloudX::Helper.resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])

      server_properties = {
        name: resource[:name].to_s,
        type: resource[:type].to_s,
        cores: resource[:cores],
        cpu_family: resource[:cpu_family].to_s,
        ram: resource[:ram],
        availability_zone: resource[:availability_zone].to_s,
      }

      if resource[:template_uuid]
        server_properties[:template_uuid] = resource[:template_uuid].to_s
      end

      server = Ionoscloud::Server.new(
        properties: Ionoscloud::ServerProperties.new(**server_properties),
        entities: Ionoscloud::ServerEntities.new(
          cdroms: Ionoscloud::Cdroms.new(
            items: PuppetX::IonoscloudX::Helper.cdrom_object_array_from_hashes(resource[:cdroms]),
          ),
          volumes: Ionoscloud::Volumes.new(
            items: PuppetX::IonoscloudX::Helper.volume_object_array_from_hashes(resource[:volumes]),
          ),
          nics: Ionoscloud::Nics.new(
            items: PuppetX::IonoscloudX::Helper.nic_object_array_from_hashes(resource[:nics], datacenter_id),
          ),
        ),
      )
      server, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_post_with_http_info(datacenter_id, server)
      PuppetX::IonoscloudX::Helper.wait_request(headers)

      if resource[:boot_volume] && resource[:volumes]
        if PuppetX::IonoscloudX::Helper.validate_uuid_format(resource[:boot_volume].to_s)
          boot_volume_id = resource[:boot_volume].to_s
        else
          volume = Ionoscloud::ServersApi.new.datacenters_servers_volumes_get(datacenter_id, server.id, depth: 1).items.find do |volume|
            volume.properties.name == resource[:boot_volume].to_s
          end
          boot_volume_id = volume.id
        end

        changes = Ionoscloud::ServerProperties.new(boot_volume: { id: boot_volume_id })
        server, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_patch_with_http_info(datacenter_id, server.id, changes)

        PuppetX::IonoscloudX::Helper.wait_request(headers)
      end

      Puppet.info("Server '#{name}' has been created.")
      @property_hash[:ensure] = :present
      @property_hash[:id] = server.id
      @property_hash[:datacenter_id] = datacenter_id
    end
  end

  def flush
    return if @property_flush.empty?
    changeable_properties = [:ram, :cpu_family, :cores, :availability_zone, :boot_volume]
    changes = Hash[ *changeable_properties.map { |property| [ property, @property_flush[property] ] }.flatten ].delete_if { |_k, v| v.nil? }

    return if changes.empty?

    Puppet.info("Updating server '#{name}', #{changes.keys}.")
    datacenter_id = PuppetX::IonoscloudX::Helper.resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    server_id = PuppetX::IonoscloudX::Helper.server_from_name(name, datacenter_id).id
    changes = Ionoscloud::ServerProperties.new(**changes)

    _, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_patch_with_http_info(datacenter_id, server_id, changes)

    PuppetX::IonoscloudX::Helper.wait_request(headers)

    changeable_properties.each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
    @property_flush = {}
  end

  def suspend
    Puppet.info("Suspending server #{name}")

    datacenter_id = PuppetX::IonoscloudX::Helper.resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    _, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_suspend_post_with_http_info(
      datacenter_id, PuppetX::IonoscloudX::Helper.server_from_name(name, datacenter_id).id
    )
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:ensure] = :suspended
  end

  def resume
    Puppet.info("Resuming server #{name}")

    datacenter_id = PuppetX::IonoscloudX::Helper.resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    _, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_resume_post_with_http_info(
      datacenter_id, PuppetX::IonoscloudX::Helper.server_from_name(name, datacenter_id).id
    )
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:ensure] = :running
  end

  def restart
    Puppet.info("Restarting server #{name}")

    datacenter_id = PuppetX::IonoscloudX::Helper.resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    _, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_reboot_post_with_http_info(
      datacenter_id, PuppetX::IonoscloudX::Helper.server_from_name(name, datacenter_id).id
    )
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:ensure] = :present
  end

  def stop
    create unless exists?
    Puppet.info("Stopping server #{name}")

    datacenter_id = PuppetX::IonoscloudX::Helper.resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    _, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_stop_post_with_http_info(
      datacenter_id, PuppetX::IonoscloudX::Helper.server_from_name(name, datacenter_id).id
    )
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:ensure] = :stopped
  end

  def destroy
    datacenter_id = PuppetX::IonoscloudX::Helper.resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    server_id = PuppetX::IonoscloudX::Helper.server_from_name(resource[:name], datacenter_id).id
    destroy_volumes(datacenter_id, server_id) if !resource[:purge_volumes].nil? && resource[:purge_volumes].to_s == 'true'

    Puppet.info("Deleting server #{name}.")

    _, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_delete_with_http_info(datacenter_id, server_id)
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:ensure] = :absent
  end

  def destroy_volumes(datacenter_id, server_id)
    headers_list = []

    Ionoscloud::ServersApi.new.datacenters_servers_volumes_get(
      datacenter_id,
      server_id,
      depth: 1,
    ).items.each do |volume|
      Puppet.info("Deleting volume #{volume.properties.name}")

      _, _, headers = Ionoscloud::VolumesApi.new.datacenters_volumes_delete_with_http_info(datacenter_id, volume.id)
      headers_list << headers
    end

    headers_list.each { |headers| PuppetX::IonoscloudX::Helper.wait_request(headers) }
  end
end
