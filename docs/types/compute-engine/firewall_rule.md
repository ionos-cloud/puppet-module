# firewall_rule

Type representing a IonosCloud firewall rule.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the firewall rule.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| source_mac | No | Only traffic originating from the respective MAC address is allowed. Valid format: aa:bb:cc:dd:ee:ff.   |
| source_ip | No | Only traffic originating from the respective IPv4 address is allowed.   |
| target_ip | No | In case the target NIC has multiple IP addresses, only traffic directed to the respective IP address of the NIC is allowed.   |
| port_range_start | No | Defines the start range of the allowed port (from 1 to 65534) if protocol TCP or UDP is chosen.   |
| port_range_end | No | Defines the end range of the allowed port (from 1 to 65534) if the protocol TCP or UDP is chosen.   |
| icmp_type | No | Defines the allowed type (from 0 to 254) if the protocol ICMP is chosen.   |
| icmp_code | No | Defines the allowed code (from 0 to 254) if protocol ICMP is chosen.   |
| type | No | The type of firewall rule. If is not specified, it will take the default value INGRESS.   |
| protocol | No | The protocol for the firewall rule.  Valid values are `TCP`, `UDP`, `ICMP`, `ANY`.  |
| datacenter_id | No | The ID of the virtual data center where the NIC will reside.   |
| datacenter_name | No | The name of the virtual data center where the NIC will reside.   |
| server_id | No | The server ID the NIC will be attached to.   |
| server_name | No | The server name the NIC will be attached to.   |
| nic_id | No | The NIC ID the NIC will be attached to.   |
| nic_name | No | The name of the NIC the firewall rule will be added to.   |
| id | No | The Firewall Rule ID.   |
***


### Changeable properties:

* icmp_code
* icmp_type
* port_range_start
* port_range_end
* source_mac
* source_ip
* target_ip
* type


## Examples

### To list resources:
```bash
puppet resource firewall_rule
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
$datacenter_name = 'MyDataCenter'
$server_name = 'worker4'
$nic = 'testnic3'

firewall_rule { 'SSH':
  ensure           => 'present',
  datacenter_name  => 'MyDataCenter',
  nic_name         => 'testnic3',
  port_range_end   => 29,
  port_range_start => 22,
  protocol         => 'TCP',
  provider         => 'v1',
  server_name      => 'worker4',
  type             => 'INGRESS',
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

