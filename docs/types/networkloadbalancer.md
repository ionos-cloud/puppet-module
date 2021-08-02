# networkloadbalancer

Type representing a IonosCloud Network Load Balancer.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the Network Load Balancer.   |

## Properties:

| Name | Required | Description | Default Value |
| :--- | :-: | :--- | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  | - |
| ips | No | Collection of IP addresses of the Network Load Balancer. (inbound and outbound) IP of the listenerLan must be a customer reserved IP for the public load balancer and private IP for the private load balancer.   | - |
| lb_private_ips | No | Collection of private IP addresses with subnet mask of the Network Load Balancer. IPs must contain valid subnet mask. If user will not provide any IP then the system will generate one IP with /24 subnet.   | - |
| listener_lan | No | Id of the listening LAN. (inbound)   | - |
| target_lan | No | Id of the balanced private target LAN. (outbound)   | - |
| rules | No | A list of flow logs associated to the Network Load Balancer.   | - |
| flowlogs | No | A list of flow logs associated to the Network Load Balancer.   | - |
| datacenter_id | No | The ID of the virtual data center where the Network Load Balancer will reside.   | - |
| datacenter_name | No | The name of the virtual data center where the Network Load Balancer will reside.   | - |
| id | No | The Network Load Balancer ID.   | - |
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
-> networkloadbalancer { 'testnetlb':
  datacenter_name => $datacenter_name,
  ips             => ['158.222.102.243'],
  lb_private_ips  => ['10.12.106.225/24', '10.12.106.222/24'],
  target_lan      => 3,
  listener_lan    => 1,
  flowlogs        => [
    {
      name      => 'test123123',
      action    => 'ALL',
      bucket    => 'testtest234134124214',
      direction => 'INGRESS',
    }
  ],
  rules           => [
    {
      name             => 'regula',
      algorithm        => 'ROUND_ROBIN',
      protocol         => 'TCP',
      listener_ip      => '158.222.102.243',
      listener_port    => 22,
      health_check     => {
        client_timeout  => 50000,
        connect_timeout => 5001,
        target_timeout  => 50000,
        retries         => 4
      },
      targets          =>[
        ip             => '1.1.1.1',
        port           => 22,
        weight         => 1,
        'health_check' => {
          check          => true,
          check_interval => 2000,
          maintenance    => false,
        },
      ],
    },
    {
      name          => 'regula2',
      algorithm     => 'ROUND_ROBIN',
      protocol      => 'TCP',
      listener_ip   => '158.222.102.243',
      listener_port => 23,
      health_check  => {
        client_timeout  => 50000,
        connect_timeout => 5001,
        target_timeout  => 50000,
        retries         => 4
      },
      targets       =>[
      ],
    },
]
}

```
