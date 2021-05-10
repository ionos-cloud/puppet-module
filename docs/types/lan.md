# lan

Type representing a ProfitBricks LAN.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the LAN.   |

## Properties:

| Name | Required | Description | Default Value |
| :--- | :-: | :--- | :--- |
| ensure | No |   Valid values are `present`, `absent`.  | - |
| public | No | Set whether LAN will face the public Internet or not.  Valid values are `true`, `false`.  | false |
| pcc | No | Set the name of the PCC to which the LAN is to be attached.   | - |
| ip_failover | No | IP failover group.   | - |
| id | No | The LAN ID.   | - |
| datacenter_id | No | The ID of the virtual data center where the LAN will reside.   | - |
| datacenter_name | No | The name of the virtual data center where the LAN will reside.   | - |
***


### Changeable properties:

No Changeable properties


## Example

```text
$datacenter_name = 'MyDataCenter'

lan { 'public' :
  ensure          => present,
  public          => true,
  datacenter_name => $datacenter_name
}

```
