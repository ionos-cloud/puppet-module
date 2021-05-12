# k8s_nodepool

Type representing a Ionoscloud K8s Nodepool.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the K8s Nodepool.   |

## Properties:

| Name | Required | Description | Default Value |
| :--- | :-: | :--- | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  | - |
| k8s_version | No | The K8s version of the K8s Nodepool.   | - |
| maintenance_day | No | The maintenance day of the K8s Nodepool.   | - |
| maintenance_time | No | The maintenance time of the K8s Nodepool.   | - |
| datacenter_name | No | The datacenter used by the K8s Nodepool.   | - |
| node_count | No | The number of nodes in the nodepool.   | - |
| min_node_count | No | The minimum number of nodes in the nodepool.   | - |
| max_node_count | No | The maximum number of nodes in the nodepool.   | - |
| cpu_family | No | The CPU family of the nodes.  Valid values are `AMD_OPTERON`, `INTEL_XEON`, `INTEL_SKYLAKE`.  | AMD_OPTERON |
| cores_count | No | The number of CPU cores assigned to the node.   | - |
| ram_size | No | The amount of RAM in MB assigned to the node.   | - |
| availability_zone | No | The availability zone of where the server will reside.  Valid values are `AUTO`, `ZONE_1`, `ZONE_2`.  | AUTO |
| storage_type | No | The volume type.  Valid values are `HDD`, `SSD`.  | HDD |
| storage_size | No | The size of the volume in GB.   | - |
| lans | No | The list of additional private LANs attached to worker nodes.   | - |
| cluster_name | No | The name of the K8s used by the K8s Nodepool.   | - |
| id | No | The ID of the K8s Nodepool.   | - |
| datacenter_id | No | The datacenter used by the K8s Nodepool.   | - |
| cluster_id | No | The ID of the K8s cluster of the K8s Nodepool.   | - |
| state | No | She state of the K8s Nodepool.   | - |
| k8s_nodes | No | A list of K8s nodes that exist in the nodepool.   | - |
***


### Changeable properties:

* k8s_version
* node_count
* maintenance_day
* maintenance_time
* min_node_count
* max_node_count
* lans


## Example

```text
$cluster_name = 'cluster_name'
$datacenter_name = 'datacenter_name'

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
  lans              => [4, 7, 5],
}

```
