# ipblock

Type representing a IonosCloud IP block.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the IP block.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| location | No | The IP block's location.   |
| size | No | The size of the IP block.   |
| id | No | The IP block's ID.   |
| created_by | No | The user who created the IP block.   |
| ips | No | The IPs allocated to the IP block.   |
| ip_consumers | No | Read-Only attribute. Lists consumption detail of an individual ip   |
***


### Changeable properties:

No Changeable properties


## Examples

### To list resources:
```bash
puppet resource ipblock
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
ipblock { 'puppet_demo':
  ensure   => present,
  location => 'us/ewr',
  size     => 2
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

