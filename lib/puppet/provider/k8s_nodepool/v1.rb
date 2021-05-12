require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:k8s_nodepool).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    PuppetX::IonoscloudX::Helper::ionoscloud_config
    super(*args)
    @property_flush = {}
  end
  
  def self.instances
    PuppetX::IonoscloudX::Helper::ionoscloud_config

    Ionoscloud::KubernetesApi.new.k8s_get(depth: 3).items.map do |k8s_cluster|
        nodepools = []
        # Ignore data center if name is not defined.
        unless k8s_cluster.properties.name.nil? || k8s_cluster.properties.name.empty?
          Ionoscloud::KubernetesApi.new.k8s_nodepools_get(k8s_cluster.id, depth: 1).items.each do |nodepool|
            unless nodepool.properties.name.nil? || nodepool.properties.name.empty?
                nodes = Ionoscloud::KubernetesApi.new.k8s_nodepools_nodes_get(k8s_cluster.id, nodepool.id, depth: 1)
                nodepools << new(instance_to_hash(nodepool, k8s_cluster, nodes))
            end
          end
        end
        nodepools
      end.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:name] == prov.name
      end
    end
  end

  def self.instance_to_hash(instance, cluster, nodes)
    {
      id: instance.id,
      name: instance.properties.name,
      cluster_id: cluster.id,
      cluster_name: cluster.properties.name,
      datacenter_id: instance.properties.datacenter_id,
      datacenter_name: Ionoscloud::DataCenterApi.new.datacenters_find_by_id(instance.properties.datacenter_id).properties.name,
      node_count: instance.properties.node_count,
      min_node_count: instance.properties.auto_scaling.min_node_count,
      max_node_count: instance.properties.auto_scaling.max_node_count,
      cpu_family: instance.properties.cpu_family,
      cores_count: instance.properties.cores_count,
      ram_size: instance.properties.ram_size,
      storage_type: instance.properties.storage_type,
      storage_size: instance.properties.storage_size,
      lans: instance.properties.lans.map { |el| el.id },
      availability_zone: instance.properties.availability_zone,
      k8s_version: instance.properties.k8s_version,
      maintenance_day: instance.properties.maintenance_window.day_of_the_week,
      maintenance_time: instance.properties.maintenance_window.time,
      k8s_nodes: nodes.items.map do
        |node|
        {
          id: node.id,
          name: node.properties.name,
          public_ip: node.properties.public_ip,
          k8s_version: node.properties.k8s_version,
          state: node.metadata.state,
        }
      end,
      state: instance.metadata.state,
      ensure: :present,
    }
  end

  def exists?
    Puppet.info("Checking if NIC #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def k8s_version=(value)
    @property_flush[:k8s_version] = value
  end

  def node_count=(value)
    @property_flush[:node_count] = value
  end

  def maintenance_day=(value)
    @property_flush[:maintenance_day] = value
  end

  def maintenance_time=(value)
    @property_flush[:maintenance_time] = value
  end

  def min_node_count=(value)
    @property_flush[:min_node_count] = value
  end

  def max_node_count=(value)
    @property_flush[:max_node_count] = value
  end

  def lans=(value)
    @property_flush[:lans] = value
  end

  def create
    cluster_id = PuppetX::IonoscloudX::Helper::resolve_cluster_id(resource[:cluster_id], resource[:cluster_name])
    datacenter_id = nil
    if resource[:datacenter_id] || resource[:datacenter_name]
      datacenter_id = PuppetX::IonoscloudX::Helper::resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name])
    end

    nodepool_properties = {
      name: resource[:name],
      k8s_version: resource[:k8s_version],
      datacenter_id: datacenter_id,
      node_count: resource[:node_count],
      cpu_family: resource[:cpu_family],
      cores_count: resource[:cores_count],
      ram_size: resource[:ram_size],
      storage_type: resource[:storage_type].to_s,
      storage_size: resource[:storage_size],
      availability_zone: resource[:availability_zone].to_s,
      lans: resource[:lans].nil? ? nil : resource[:lans].map { |el| { id: el } },
    }.delete_if { |_k, v| v.nil? }

    if resource[:maintenance_day] && resource[:maintenance_time]
      nodepool_properties[:maintenance_window] = Ionoscloud::KubernetesMaintenanceWindow.new(
        day_of_the_week: resource[:maintenance_day],
        time: resource[:maintenance_time],
      )
    end

    if resource[:min_node_count] || resource[:max_node_count]
      nodepool_properties[:auto_scaling] = Ionoscloud::KubernetesAutoScaling.new(
        min_node_count: resource[:min_node_count],
        max_node_count: resource[:max_node_count],
      )
    end

    nodepool = Ionoscloud::KubernetesNodePool.new(
      properties: Ionoscloud::KubernetesNodePoolProperties.new(
        **nodepool_properties,
      ),
    )

    nodepool, _, headers = Ionoscloud::KubernetesApi.new.k8s_nodepools_post_with_http_info(cluster_id, nodepool)
    PuppetX::IonoscloudX::Helper::wait_request(headers)

    Puppet.info("Created a new K8s Npdepool named #{resource[:name]}.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = nodepool.id
    @property_hash[:cluster_id] = cluster_id
    @property_hash[:datacenter_id] = datacenter_id
  end

  def flush
    if @property_flush.empty?
      return
    end
    datacenter_id = @property_hash[:datacenter_id]
    if @property_flush[:datacenter_id] || @property_flush[:datacenter_name]
      datacenter_id = PuppetX::IonoscloudX::Helper::resolve_datacenter_id(@property_flush[:datacenter_id], @property_flush[:datacenter_name])
    end

    nodepool_properties = {
      k8s_version: @property_flush[:k8s_version] || @property_hash[:k8s_version],
      node_count: @property_flush[:node_count] || @property_hash[:node_count],
      lans: @property_flush[:lans].nil? ? nil : @property_flush[:lans].map { |el| { id: el } },
      maintenance_window: Ionoscloud::KubernetesMaintenanceWindow.new(
        day_of_the_week: @property_flush[:maintenance_day] || @property_hash[:maintenance_day],
        time: @property_flush[:maintenance_time] || @property_hash[:maintenance_time],
      ),
      auto_scaling: Ionoscloud::KubernetesAutoScaling.new(
        min_node_count: @property_flush[:min_node_count] || @property_hash[:min_node_count],
        max_node_count: @property_flush[:max_node_count] || @property_hash[:max_node_count],
      ),
    }

    new_k8s_nodepool = Ionoscloud::KubernetesNodePool.new(properties: Ionoscloud::KubernetesNodePoolProperties.new(nodepool_properties))
    k8s_nodepool, _, headers = Ionoscloud::KubernetesApi.new.k8s_nodepools_put_with_http_info(@property_hash[:cluster_id], @property_hash[:id], new_k8s_nodepool)
    PuppetX::IonoscloudX::Helper::wait_request(headers)
  end

  def destroy
    _, _, headers = Ionoscloud::KubernetesApi.new.k8s_nodepools_delete_with_http_info(@property_hash[:cluster_id], @property_hash[:id])
    PuppetX::IonoscloudX::Helper::wait_request(headers)
    @property_hash[:ensure] = :absent
  end
end
