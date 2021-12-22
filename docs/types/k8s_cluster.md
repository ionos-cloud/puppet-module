# k8s_cluster

Type representing a Ionoscloud K8s Cluster.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the K8s Cluster.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| k8s_version | No | The K8s version of the K8s Cluster.   |
| maintenance_day | No | The maintenance day of the K8s Cluster.   |
| maintenance_time | No | The maintenance time of the K8s Cluster.   |
| api_subnet_allow_list | No | Access to the K8s API server is restricted to these CIDRs. Cluster-internal traffic is not affected by this restriction. If no allowlist is specified, access is not restricted. If an IP without subnet mask is provided, the default value will be used: 32 for IPv4 and 128 for IPv6.   |
| s3_buckets | No | List of S3 bucket configured for K8s usage. For now it contains only an S3 bucket used to store K8s API audit logs   |
| id | No | The ID of the K8s Cluster.   |
| state | No | She state of the K8s Cluster.   |
| k8s_nodepools | No | A list of K8s nodepool that exist in the cluster.   |
| available_upgrade_versions | No | List of available versions for upgrading the cluster.   |
| viable_node_pool_versions | No | List of versions that may be used for node pools under this cluster.   |
***


### Changeable properties:

* k8s_version
* maintenance_day
* maintenance_time
* api_subnet_allow_list
* s3_buckets


## Example

```text
k8s_cluster { 'myClustertest' :
  ensure           => present,
  k8s_version      => '1.18.5',
  maintenance_day  => 'Sunday',
  maintenance_time => '14:53:00Z',
}

```
