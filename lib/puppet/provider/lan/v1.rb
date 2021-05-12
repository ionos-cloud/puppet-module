require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:lan).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    PuppetX::IonoscloudX::Helper.ionoscloud_config
    super(*args)
    @property_flush = {}
  end

  def self.instances
    PuppetX::IonoscloudX::Helper.ionoscloud_config
    Ionoscloud::DataCenterApi.new.datacenters_get(depth: 1).items.map { |datacenter|
      lans = []
      # Ignore data center if name is not defined.
      unless datacenter.properties.name.nil? || datacenter.properties.name.empty?
        Ionoscloud::LanApi.new.datacenters_lans_get(datacenter.id, depth: 1).items.each do |lan|
          unless lan.properties.name.nil? || lan.properties.name.empty?
            lans << new(instance_to_hash(lan, datacenter))
          end
        end
      end
      lans
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
    pcc_name = instance.properties.pcc.nil? ? nil : Ionoscloud::PrivateCrossConnectApi.new.pccs_find_by_id(instance.properties.pcc).properties.name
    {
      id: instance.id,
      datacenter_id: datacenter.id,
      datacenter_name: datacenter.properties.name,
      name: instance.properties.name,
      ip_failover: instance.properties.ip_failover.map do |el|
        el = el.to_hash
        el[:nic_uuid] = el.delete :nicUuid
        el.transform_keys(&:to_s)
      end,
      public: instance.properties.public,
      pcc: pcc_name,
      ensure: :present,
    }
  end

  def public=(value)
    @property_flush[:public] = value
  end

  def pcc=(value)
    @property_flush[:pcc] = value
  end

  def ip_failover=(value)
    ip_failovers = value.map { |ip_failover| { ip: ip_failover['ip'], nicUuid: ip_failover['nic_uuid'] } }
    @property_flush[:ip_failover] = ip_failovers
  end

  def exists?
    Puppet.info("Checking if LAN #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def flush
    changeable_properties = [:public, :ip_failover, :pcc]
    changes = Hash[ *changeable_properties.flat_map { |property| [ property, @property_flush[property] ] } ].delete_if { |_k, v| v.nil? }

    return if changes.empty?

    Puppet.info("Updating Lan '#{name}', #{changes.keys}.")

    if changes[:pcc]
      changes[:pcc] = if changes[:pcc] == 'nil'
                        nil
                      else
                        PuppetX::IonoscloudX::Helper.pcc_from_name(changes[:pcc]).id
                      end
    end

    if changes[:ip_failover]
      changes[:ipFailover] = changes[:ip_failover]
      changes.delete(:ip_failover)
    end

    _, _, headers = Ionoscloud::LanApi.new.datacenters_lans_patch_with_http_info(
      @property_hash[:datacenter_id], @property_hash[:id], changes
    )

    PuppetX::IonoscloudX::Helper.wait_request(headers)

    changeable_properties.each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
  end

  def create
    lan = Ionoscloud::Lan.new(
      properties: Ionoscloud::LanProperties.new(
        name: resource[:name],
        public: resource[:public] || false,
        pcc: resource[:pcc],
      ),
    )

    datacenter_id = PuppetX::IonoscloudX::Helper.resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    lan, _, headers = Ionoscloud::LanApi.new.datacenters_lans_post_with_http_info(datacenter_id, lan)
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    if resource[:ip_failover]
      ip_failover_changes = { ip_failover: resource[:ip_failover].map { |ip_failover| Ionoscloud::IPFailover.new(ip: ip_failover['ip'], nic_uuid: ip_failover['nic_uuid']) } }

      lan, _, headers = Ionoscloud::LanApi.new.datacenters_lans_patch_with_http_info(
        resource[:datacenter_id], lan.id, Ionoscloud::LanProperties.new(**ip_failover_changes)
      )
      PuppetX::IonoscloudX::Helper.wait_request(headers)
    end

    Puppet.info("Creating a new LAN called #{name}.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = lan.id
    @property_hash[:datacenter_id] = datacenter_id
  end

  def destroy
    _, _, headers = Ionoscloud::LanApi.new.datacenters_lans_delete_with_http_info(@property_hash[:datacenter_id], @property_hash[:id])
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    @property_hash[:ensure] = :absent
  end
end
