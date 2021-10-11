# natgateway

Type representing a IonosCloud NAT Gateway.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the NAT Gateway.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| public_ips | No | Collection of public IP addresses of the NAT gateway. Should be customer reserved IP addresses in that location.   |
| lans | No | Collection of LANs connected to the NAT gateway. IPs must contain valid subnet mask. If user will not provide any IP then system will generate an IP with /24 subnet.   |
| rules | No | A list of flow logs associated to the NAT Gateway.   |
| flowlogs | No | A list of flow logs associated to the NAT Gateway.   |
| datacenter_id | No | The ID of the virtual data center where the NAT Gateway will reside.   |
| datacenter_name | No | The name of the virtual data center where the NAT Gateway will reside.   |
| id | No | The NAT Gateway ID.   |
***


### Changeable properties:

* public_ips
* lans
* rules
* flowlogs


## Example

```text
$datacenter_name = 'testdc1'

datacenter { $datacenter_name :
  ensure      => present,
  location    => 'us/las',
  description => 'my data center desc.'
}
-> natgateway { 'testnatg':
  datacenter_name => $datacenter_name,
  public_ips      => ['158.222.103.21'],
  lans            => [
  ],
  flowlogs        => [
    {
      name      => 'test123123',
      action    => 'ALL',
      bucket    => 'testtest234134124214',
      direction => 'EGRESS',
    }
  ],
  rules           => [
    {
      name              => 'test_rule',
      protocol          => 'TCP',
      source_subnet     => '192.168.0.1/32',
      target_subnet     => '192.168.0.4/32',
      public_ip         => '158.222.103.21',
      target_port_range => {
        start => 22,
        end   => 27,
      }
    },
    {
      name              => 'test_rule2',
      protocol          => 'TCP',
      source_subnet     => '192.168.0.1/32',
      target_subnet     => '192.168.0.4/32',
      public_ip         => '158.222.103.21',
      target_port_range => {
        start => 23,
        end   => 26,
      }
    },
    {
      name              => 'test_rule3',
      protocol          => 'TCP',
      source_subnet     => '192.168.0.1/32',
      target_subnet     => '192.168.0.4/32',
      public_ip         => '158.222.103.21',
      target_port_range => {
        start => 22,
        end   => 24,
      }
    },
  ]
}

```
