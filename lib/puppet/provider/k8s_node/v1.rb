require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:k8s_node).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def initialize(*args)
    super(*args)
    @property_flush = {}
  end

  def self.instances
    PuppetX::IonoscloudX::Helper.kubernetes_api.k8s_get(depth: 1).items.map { |cluster|
      nodes = []
      # Ignore data center if name is not defined.
      unless cluster.properties.name.nil? || cluster.properties.name.empty?
        PuppetX::IonoscloudX::Helper.kubernetes_api.k8s_nodepools_get(cluster.id, depth: 1).items.map do |nodepool|
          next if nodepool.properties.name.nil? || nodepool.properties.name.empty?
          PuppetX::IonoscloudX::Helper.kubernetes_api.k8s_nodepools_nodes_get(cluster.id, nodepool.id, depth: 1).items.map do |node|
            unless node.properties.name.nil? || node.properties.name.empty?
              nodes << new(instance_to_hash(node, nodepool, cluster))
            end
          end
        end
      end
      nodes
    }.flatten
  end

  def self.prefetch(resources)
    resources.each_key do |key|
      resource = resources[key]
      next unless instances.count { |instance|
        instance.name == key &&
        (resource[:cluster_id] == instance.cluster_id || resource[:cluster_name] == instance.cluster_name) &&
        (resource[:nodepool_id] == instance.nodepool_id || resource[:nodepool_name] == instance.nodepool_name)
      } > 1
      raise Puppet::Error, "Multiple #{resources[key].type} instances found for '#{key}'!"
    end

    instances.each do |prov|
      next unless (resource = resources[prov.name])
      if (resource[:cluster_id] == prov.cluster_id || resource[:cluster_name] == prov.cluster_name) &&
         (resource[:nodepool_id] == prov.nodepool_id || resource[:nodepool_name] == prov.nodepool_name)
        resource.provider = prov
      end
    end
  end

  def self.instance_to_hash(instance, nodepool, cluster)
    {
      id: instance.id,
      cluster_id: cluster.id,
      cluster_name: cluster.properties.name,
      nodepool_id: nodepool.id,
      nodepool_name: nodepool.properties.name,
      name: instance.properties.name,
      public_ip: instance.properties.public_ip,
      k8s_version: instance.properties.k8s_version,
      private_ip: instance.properties.private_ip,
      state: instance.metadata.state,
      ensure: :present,
    }
  end

  def exists?
    Puppet.info("Checking if K8S Node #{resource[:name]} exists.")
    @property_hash[:ensure] == :present
  end
end
