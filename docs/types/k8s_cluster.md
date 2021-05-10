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
| maintenance_day | No | The maintenance day of the K8s Cluster.   | - |
| maintenance_time | No | The maintenance time of the K8s Cluster.   | - |
| id | No | The ID of the K8s Cluster.   | - |
| state | No | She state of the K8s Cluster.   | - |
| k8s_nodepools | No | A list of K8s nodepool that exist in the cluster.   | - |
***


### Changeable properties:

* k8s_version
* maintenance_day
* maintenance_time


## Example

```text
k8s_cluster { 'myCluster' :
  ensure           => present,
  k8s_version      => '1.18.15',
  maintenance_day  => 'Sunday',
  maintenance_time => '14:53:00Z',
}

```
