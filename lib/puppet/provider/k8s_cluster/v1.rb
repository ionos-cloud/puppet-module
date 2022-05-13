require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:k8s_cluster).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    super(*args)
    @property_flush = {}
  end

  def self.instances
    k8s_clusters = []
    PuppetX::IonoscloudX::Helper.kubernetes_api.k8s_get(depth: 3).items.each do |k8s_cluster|
      # Ignore data centers if name is not defined.
      k8s_clusters << new(instance_to_hash(k8s_cluster)) unless k8s_cluster.properties.name.nil? || k8s_cluster.properties.name.empty?
    end
    k8s_clusters.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:name] == prov.name
      end
    end
  end

  def self.instance_to_hash(instance)
    {
      id: instance.id,
      name: instance.properties.name,
      k8s_version: instance.properties.k8s_version,
      maintenance_day: instance.properties.maintenance_window.day_of_the_week,
      maintenance_time: instance.properties.maintenance_window.time,
      state: instance.metadata.state,
      available_upgrade_versions: instance.properties.available_upgrade_versions,
      viable_node_pool_versions: instance.properties.viable_node_pool_versions,
      api_subnet_allow_list: instance.properties.api_subnet_allow_list,
      s3_buckets: instance.properties.s3_buckets.nil? ? [] : instance.properties.s3_buckets.map { |s3_bucket| { name: s3_bucket.name } },
      k8s_nodepools: instance.entities.nodepools.items.map do |nodepool|
        {
          id: nodepool.id,
          name: nodepool.properties.name,
          datacenter_id: nodepool.properties.datacenter_id,
          datacenter_name: PuppetX::IonoscloudX::Helper.datacenters_api.datacenters_find_by_id(nodepool.properties.datacenter_id).properties.name,
          node_count: nodepool.properties.node_count,
          cpu_family: nodepool.properties.cpu_family,
          cores_count: nodepool.properties.cores_count,
          ram_size: nodepool.properties.ram_size,
          storage_type: nodepool.properties.storage_type,
          storage_size: nodepool.properties.storage_size,
          availability_zone: nodepool.properties.availability_zone,
          k8s_version: nodepool.properties.k8s_version,
          maintenance_day: nodepool.properties.maintenance_window.day_of_the_week,
          maintenance_time: nodepool.properties.maintenance_window.time,
        }
      end,
      ensure: :present,
    }
  end

  def exists?
    Puppet.info("Checking if K8s cluster #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end

  def k8s_version=(value)
    @property_flush[:k8s_version] = value
  end

  def maintenance_day=(value)
    @property_flush[:maintenance_day] = value
  end

  def maintenance_time=(value)
    @property_flush[:maintenance_time] = value
  end

  def api_subnet_allow_list=(value)
    @property_flush[:api_subnet_allow_list] = value
  end

  def s3_buckets=(value)
    @property_flush[:s3_buckets] = value
  end

  def create
    cluster_properties = {
      name: resource[:name],
      k8s_version: resource[:k8s_version],
      api_subnet_allow_list: resource[:api_subnet_allow_list],
      s3_buckets: resource[:s3_buckets],
    }

    if resource[:maintenance_day] && resource[:maintenance_time]
      cluster_properties[:maintenance_window] = Ionoscloud::KubernetesMaintenanceWindow.new(
        day_of_the_week: resource[:maintenance_day],
        time: resource[:maintenance_time],
      )
    end

    k8s_cluster = Ionoscloud::KubernetesClusterForPost.new(
      properties: Ionoscloud::KubernetesClusterPropertiesForPost.new(
        **cluster_properties,
      ),
    )

    k8s_cluster, _, headers = PuppetX::IonoscloudX::Helper.kubernetes_api.k8s_post_with_http_info(k8s_cluster)
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    Puppet.info("Created a new K8s Cluster named #{resource[:name]}.")
    @property_hash[:ensure] = :present
    @property_hash[:id] = k8s_cluster.id
  end

  def flush
    return if @property_flush.empty?
    cluster_properties = {
      name: @property_hash[:name],
      k8s_version: @property_flush[:k8s_version] || @property_hash[:k8s_version],
      api_subnet_allow_list: @property_flush[:api_subnet_allow_list] || @property_hash[:api_subnet_allow_list],
      s3_buckets: @property_flush[:s3_buckets] || @property_hash[:s3_buckets],
      maintenance_window: Ionoscloud::KubernetesMaintenanceWindow.new(
        day_of_the_week: @property_flush[:maintenance_day] || @property_hash[:maintenance_day],
        time: @property_flush[:maintenance_time] || @property_hash[:maintenance_time],
      ),
    }

    new_k8s_cluster = Ionoscloud::KubernetesClusterForPut.new(properties: Ionoscloud::KubernetesClusterPropertiesForPut.new(cluster_properties))
    _, _, headers = PuppetX::IonoscloudX::Helper.kubernetes_api.k8s_put_with_http_info(@property_hash[:id], new_k8s_cluster)
    PuppetX::IonoscloudX::Helper.wait_request(headers)

    [:k8s_version, :maintenance_day, :maintenance_time].each do |property|
      @property_hash[property] = @property_flush[property] if @property_flush[property]
    end
    @property_flush = {}
  end

  def destroy
    _, _, headers = PuppetX::IonoscloudX::Helper.kubernetes_api.k8s_delete_with_http_info(@property_hash[:id])
    PuppetX::IonoscloudX::Helper.wait_request(headers)
    @property_hash[:ensure] = :absent
  end
end
