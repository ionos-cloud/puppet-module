# k8s_nodepool

Type representing a Ionoscloud K8s Nodepool.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the K8s Nodepool.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| k8s_version | No | The K8s version of the K8s Nodepool.   |
| maintenance_day | No | The maintenance day of the K8s Nodepool.   |
| maintenance_time | No | The maintenance time of the K8s Nodepool.   |
| datacenter_name | No | The datacenter used by the K8s Nodepool.   |
| node_count | No | The number of nodes in the nodepool.   |
| min_node_count | No | The minimum number of nodes in the nodepool.   |
| max_node_count | No | The maximum number of nodes in the nodepool.   |
| cpu_family | No | The CPU family of the nodes.  Valid values are `AMD_OPTERON`, `INTEL_XEON`, `INTEL_SKYLAKE`.  |
| cores_count | No | The number of CPU cores assigned to the node.   |
| ram_size | No | The amount of RAM in MB assigned to the node.   |
| availability_zone | No | The availability zone of where the server will reside.  Valid values are `AUTO`, `ZONE_1`, `ZONE_2`.  |
| storage_type | No | The volume type.   |
| storage_size | No | The size of the volume in GB.   |
| lans | No | The list of additional private LANs attached to worker nodes.   |
| public_ips | No | Optional array of reserved public IP addresses to be used by the nodes. IPs must be from same location as the data center used for the node pool. The array must contain one extra IP than maximum number of nodes could be. (nodeCount+1 if fixed node amount or maxNodeCount+1 if auto scaling is used) The extra provided IP Will be used during rebuilding of nodes.   |
| available_upgrade_versions | No | List of available versions for upgrading the node pool.   |
| cluster_name | No | The name of the K8s used by the K8s Nodepool.   |
| labels | No | The map of labels attached to node pool.   |
| annotations | No | The map of annotations attached to node pool.   |
| id | No | The ID of the K8s Nodepool.   |
| datacenter_id | No | The datacenter used by the K8s Nodepool.   |
| cluster_id | No | The ID of the K8s cluster of the K8s Nodepool.   |
| state | No | The state of the K8s Nodepool.   |
| k8s_nodes | No | A list of K8s nodes that exist in the nodepool.   |
***


### Changeable properties:

* k8s_version
* node_count
* maintenance_day
* maintenance_time
* min_node_count
* max_node_count
* lans
* public_ips


## Examples

### To list resources:
```bash
puppet resource k8s_nodepool
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
$cluster_name = 'puppet_module_testa'
$datacenter_name = 'testdc1'

k8s_nodepool { 'nodepool_test' :
  ensure            => present,
  cluster_name      => $cluster_name,
  datacenter_name   => $datacenter_name,
  k8s_version       => '1.18.5',
  maintenance_day   => 'Sunday',
  maintenance_time  => '13:53:00Z',
  node_count        => 1,
  cores_count       => 1,
  cpu_family        => 'INTEL_XEON',
  ram_size          => 2048,
  storage_type      => 'SSD',
  storage_size      => 10,
  min_node_count    => 1,
  max_node_count    => 2,
  availability_zone => 'AUTO',
  lans              => [
    {
      'id'     => 2,
      'dhcp'   => true,
      'routes' => [],
    },
    {
      id     => 3,
      dhcp   => true,
      routes => [{
        network    => '127.0.0.1/24',
        gateway_ip => '127.0.0.1',
      }],
    },
  ],
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

