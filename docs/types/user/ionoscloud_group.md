# ionoscloud_group

Type representing a IonosCloud group.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The group name.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| create_data_center | No | Indicates if the group is allowed to create virtual data centers.  Valid values are `true`, `false`.  |
| create_snapshot | No | Indicates if the group is allowed to create snapshots.  Valid values are `true`, `false`.  |
| reserve_ip | No | Indicates if the group is allowed to reserve IP addresses.  Valid values are `true`, `false`.  |
| access_activity_log | No | Indicates if the group is allowed to access the activity log.  Valid values are `true`, `false`.  |
| s3_privilege | No | Indicates if the group is allowed is allowed to manage S3.  Valid values are `true`, `false`.  |
| create_backup_unit | No | Indicates if the group is allowed to manage backup units.  Valid values are `true`, `false`.  |
| create_internet_access | No | Indicates if the group is allowed to create internet access.  Valid values are `true`, `false`.  |
| create_k8s_cluster | No | Indicates if the group is allowed to create kubernetes cluster.  Valid values are `true`, `false`.  |
| create_pcc | No | Indicates if the group is allowed to create pcc.  Valid values are `true`, `false`.  |
| create_flow_log | No | Indicates if the group is allowed to create Flow Logs.  Valid values are `true`, `false`.  |
| access_and_manage_monitoring | No | Indicates if the group is allowed to access and manage monitoring related functionality (access metrics, CRUD on alarms, alarm-actions etc) using Monotoring-as-a-Service (MaaS).  Valid values are `true`, `false`.  |
| access_and_manage_certificates | No | Indicates if the group is allowed to access and manage certificates.  Valid values are `true`, `false`.  |
| members | No | The ionoscloud users associated with the group.   |
| id | No | The group ID.   |
***


### Changeable properties:

* create_data_center
* create_snapshot
* reserve_ip
* access_activity_log
* s3_privilege
* create_backup_unit
* create_internet_access
* create_k8s_cluster
* create_pcc
* members


## Examples

### To list resources:
```bash
puppet resource ionoscloud_group
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
ionoscloud_group { 'Puppet Test' :
  ensure              => present,
  create_data_center  => false,
  create_snapshot     => false,
  reserve_ip          => true,
  access_activity_log => true,
  members             => []
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

