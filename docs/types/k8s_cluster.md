# k8s_cluster

Type representing a Ionoscloud K8s Cluster.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the K8s Cluster.   |

## Properties:

| Name | Required | Description | Default Value |
| :--- | :-: | :--- | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  | - |
| k8s_version | No | The K8s version of the K8s Cluster.   | - |
| public | No | The indicator if the cluster is public or private. Be aware that setting it to false is currently in beta phase.  Valid values are `true`, `false`.  | true |
| gateway_ip | No | The IP address of the gateway used by the cluster. This is mandatory when `public` is set to `false` and should not be provided otherwise.   | - |
| maintenance_day | No | The maintenance day of the K8s Cluster.   | - |
| maintenance_time | No | The maintenance time of the K8s Cluster.   | - |
| id | No | The ID of the K8s Cluster.   | - |
| state | No | She state of the K8s Cluster.   | - |
| k8s_nodepools | No | A list of K8s nodepool that exist in the cluster.   | - |
| available_upgrade_versions | No | List of available versions for upgrading the cluster.   | - |
| viable_node_pool_versions | No | List of versions that may be used for node pools under this cluster.   | - |
***


### Changeable properties:

* k8s_version
* maintenance_day
* maintenance_time


## Example

```text
k8s_cluster { 'myClustertest' :
  ensure           => present,
  k8s_version      => '1.18.15',
  maintenance_day  => 'Sunday',
  maintenance_time => '14:53:00Z',
}

```
