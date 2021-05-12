require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:pcc).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    PuppetX::IonoscloudX::Helper::ionoscloud_config
    super(*args)
    @property_flush = {}
  end

  def self.instances
    PuppetX::IonoscloudX::Helper::ionoscloud_config
    datacenters = Ionoscloud::DataCenterApi.new.datacenters_get(depth: 1).items
    pccs = []
    Ionoscloud::PrivateCrossConnectApi.new.pccs_get(depth: 1).items.each do |pcc|
      # Ignore data centers if name is not defined.
      pccs << new(instance_to_hash(pcc, datacenters)) unless pcc.properties.name.nil? || pcc.properties.name.empty?
    end
    pccs.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:name] == prov.name
      end
    end
  end

  def self.instance_to_hash(instance, datacenters)
    {
      id: instance.id,
      name: instance.properties.name,
      description: instance.properties.description,
      peers: instance.properties.peers.map do |el|
        datacenter_name = datacenters.find { |datacenter| datacenter.id == el.datacenter_id }.properties.name
        { id: el.id , name: el.name, datacenter_id: el.datacenter_id, datacenter_name: datacenter_name }
      end,
      connectable_datacenters: instance.properties.connectable_datacenters.map { |el| { id: el.id } },
      ensure: :present,
    }
  end

  def description=(value)
    Puppet.info("Updating PCC #{resource[:name]} description with #{value}.")
    _, _, headers = Ionoscloud::PrivateCrossConnectApi.new.pccs_patch_with_http_info(@property_hash[:id], description: value)
    PuppetX::IonoscloudX::Helper::wait_request(headers)
    @property_hash[:description] = value
  end

  def peers=(value)
    PuppetX::IonoscloudX::Helper::peers_sync(@property_hash[:peers], value, @property_hash[:id])
  end

  def exists?
    Puppet.info("Checking if LAN #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def create
    pcc = Ionoscloud::PrivateCrossConnect.new(
      properties: Ionoscloud::PrivateCrossConnectProperties.new(
        name: resource[:name],
        description: resource[:description],
      ),
    )

    pcc, _, headers = Ionoscloud::PrivateCrossConnectApi.new.pccs_post_with_http_info(pcc)
    PuppetX::IonoscloudX::Helper::wait_request(headers)

    if resource[:peers]
      headers_list = []
      resource[:peers].each do |peer|
        datacenter_id = PuppetX::IonoscloudX::Helper::resolve_datacenter_id(peer['datacenter_id'], peer['datacenter_name'])
        peer_id = peer['id'] ? peer['id'] : PuppetX::IonoscloudX::Helper::lan_from_name(peer['name'], datacenter_id).id

        _, _, headers = Ionoscloud::LanApi.new.datacenters_lans_patch_with_http_info(datacenter_id, peer_id, pcc: pcc.id)
        headers_list << headers
      end
      headers_list.each { |headers| PuppetX::IonoscloudX::Helper::wait_request(headers) }
    end

    Puppet.info("Creating a new PCC called #{name}.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = pcc.id
  end

  def destroy
    if @property_hash[:peers]
      headers_list = []
      @property_hash[:peers].each do |peer|
        _, _, headers = Ionoscloud::LanApi.new.datacenters_lans_patch_with_http_info(peer['datacenter_id'], peer['id'], pcc: nil)
        headers_list << headers
      end
      headers_list.each { |headers| PuppetX::IonoscloudX::Helper::wait_request(headers) }
    end
    _, _, headers = Ionoscloud::PrivateCrossConnectApi.new.pccs_delete_with_http_info(@property_hash[:id])
    PuppetX::IonoscloudX::Helper::wait_request(headers)

    @property_hash[:ensure] = :absent
  end
end
