# pcc

Type representing a IonosCloud LAN.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the PCC.   |
| description |  | The description of the PCC.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No |   Valid values are `present`, `absent`.  |
| peers | No | The list of peers connected to the PCC.   |
| id | No | The PCC ID.   |
| connectable_datacenters | No | The datacenters from which you may connect to this PCC.   |
***


### Changeable properties:

* description
* peers


## Examples

### To list resources:
```bash
puppet resource pcc
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
$datacenter1_name = 'datacenter1_name'
$private_lan_in_datacenter1 = 'private_lan_in_datacenter1'
$datacenter2_name = 'datacenter1_name'
$private_lan_in_datacenter2 = 'private_lan_in_datacenter2'

pcc { 'newpcc' :
  ensure      => absent,
  description => 'descriere',
  peers       => [
    {
      name            => $private_lan_in_datacenter1,
      datacenter_name => $datacenter1_name,
    },
    {
      name            => $private_lan_in_datacenter2,
      datacenter_name => $datacenter2_name,
    },
  ]
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

