# lan

Type representing a IonosCloud LAN.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the LAN.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No |   Valid values are `present`, `absent`.  |
| public | No | Set whether LAN will face the public Internet or not.  Valid values are `true`, `false`.  |
| pcc | No | Set the name of the PCC to which the LAN is to be attached.   |
| ip_failover | No | IP failover group.   |
| id | No | The LAN ID.   |
| datacenter_id | No | The ID of the virtual data center where the LAN will reside.   |
| datacenter_name | No | The name of the virtual data center where the LAN will reside.   |
***


### Changeable properties:

* public
* pcc
* ip_failover


## Examples

### To list resources:
```bash
puppet resource lan
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
$datacenter_name = 'MyDataCenter'

lan { 'public' :
  ensure          => present,
  public          => true,
  datacenter_name => $datacenter_name
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

