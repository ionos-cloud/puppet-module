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
| nic | No | The name of the NIC the firewall rule will be added to.   |
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


## Example

```ruby
$datacenter_name = 'testdc1'
$server_name = 'worker1'
$nic = 'testnic'

firewall_rule { 'HTTP':
  datacenter_name  => $datacenter_name,
  server_name      => $server_name,
  nic              => $nic,
  protocol         => 'TCP',
  port_range_start => 80,
  port_range_end   => 83,
  source_mac       => '12:47:e9:b1:77:b4',
  source_ip        => '10.81.12.123',
  target_ip        => '10.81.12.124'
}

```
