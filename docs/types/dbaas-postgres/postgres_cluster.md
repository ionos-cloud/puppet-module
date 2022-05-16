# postgres_cluster

Type representing a Ionoscloud DBaaS Postgres Cluster.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| display_name | true | The name of the Postgres Cluster.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| restore | No | If true, restore the Cluster to the backup specified by backup_id and the time specified by recovery_target_time.  Valid values are `true`, `false`.  |
| postgres_version | Yes | The Postgres version of the Postgres Cluster.   |
| maintenance_day | No | The maintenance day of the Postgres Cluster.   |
| maintenance_time | No | The maintenance time of the Postgres Cluster.   |
| instances | Yes | The total number of instances in the cluster (one master and n-1 standbys).   |
| cores_count | Yes | The number of CPU cores assigned to the instances.   |
| ram_size | Yes | The amount of RAM in MB assigned to the instances.   |
| storage_size | Yes | The size of the volume in GB.   |
| storage_type | Yes | The volume type.   |
| location | Yes | The Postgres Cluster location.   |
| backup_location | No | The S3 location where the backups will be stored.   |
| synchronization_mode | Yes | Represents different modes of replication.   |
| connections | Yes | An array of connections to the Postgres Cluster.   |
| db_username | Yes | The username for the initial postgres user. Some system usernames are restricted (e.g. "postgres", "admin", "standby")   |
| db_password | No | The password for the initial postgres user.   |
| backup_id | No | ID of a backup for the Cluster   |
| recovery_target_time | No | Recovery target time   |
| id | No | The ID of the Postgres Cluster.   |
| state | No | The state of the Postgres Cluster.   |
| backups | No | A list of backups that exist in the Postgres Cluster.   |
| available_postgres_vesions | No | A list of Postgres Versions available for the Postgres Cluster.   |
***


### Changeable properties:

* cores_count
* ram_size
* storage_size
* maintenance_time
* maintenance_day
* postgres_version
* instances


## Examples

### To list resources:
```bash
puppet resource postgres_cluster
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
$datacenter_name = 'testdc1'
$lan_name = 1

postgres_cluster { 'test' :
  ensure               => present,
  restore              => false,
  instances            => 1,
  postgres_version     => '12',
  cores_count          => 1,
  ram_size             => 2048,
  storage_size         => 20490,
  storage_type         => 'HDD',
  synchronization_mode => 'ASYNCHRONOUS',
  location             => 'de/fra',
  backup_location      => 'eu-central-2',
  connections          => [
    'datacenter'       => $datacenter_name,
    'lan'              => $lan_name,
    'cidr'             => '192.168.1.108/24',
  ],
  db_username          => 'test',
  db_password          => '7357cluster',
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

