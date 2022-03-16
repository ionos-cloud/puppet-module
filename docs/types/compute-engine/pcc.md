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


## Example

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
