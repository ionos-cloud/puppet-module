# k8s_node

Type representing a Ionoscloud network interface.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the K8s Node.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| public_ip | No | The public IP of the K8s Node.   |
| k8s_version | No | The K8s version of the K8s Node.   |
| private_ip | No | The private IP of the K8s Node.   |
| state | No | She state of the K8s Node.   |
| nodepool_id | No | The K8s Nodepool ID the K8s Node will be attached to.   |
| nodepool_name | No | The K8s Nodepool name the K8s Node will be attached to.   |
| cluster_id | No | The ID of the virtual K8s Cluster where the K8s Node will reside.   |
| cluster_name | No | The name of the virtual K8s Cluster where the K8s Node will reside.   |
***


### Changeable properties:

No Changeable properties


## Examples

### To list resources:
```bash
puppet resource k8s_node
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

No example available
