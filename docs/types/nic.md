# nic

Type representing a IonosCloud network interface.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the NIC.   |

## Properties:

| Name | Required | Description | Default Value |
| :--- | :-: | :--- | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  | - |
| ips | No | The IPs assigned to the NIC.   | - |
| dhcp | No | Enable or disable DHCP on the NIC.  Valid values are `true`, `false`.  | false |
| lan | No | The LAN name the NIC will sit on.   | - |
| nat | No | A boolean which indicates if the NIC will perform Network Address Translation.  Valid values are `true`, `false`.  | false |
| firewall_rules | No | A list of firewall rules associated to the NIC.   | - |
| firewall_active | No | Indicates the firewall is active.  Valid values are `true`, `false`.  | false |
| server_id | No | The server ID the NIC will be attached to.   | - |
| server_name | No | The server name the NIC will be attached to.   | - |
| datacenter_id | No | The ID of the virtual data center where the NIC will reside.   | - |
| datacenter_name | No | The name of the virtual data center where the NIC will reside.   | - |
***


### Changeable properties:

* ips
* lan
* nat
* dhcp
* firewall_rules


## Example

```text
$datacenter_name = 'testdc1'
$server_name = 'worker1'
$lan_name = 'public1'

datacenter { $datacenter_name :
  ensure      => present,
  location    => 'de/fkb',
  description => 'my data center desc.'
}
-> lan { $lan_name :
  ensure          => present,
  public          => true,
  datacenter_name => $datacenter_name
}
-> server { $server_name :
  ensure          => present,
  cores           => 2,
  datacenter_name => $datacenter_name,
  ram             => 1024,
  volumes         => [
    {
      name              => 'system',
      size              => 50,
      bus               => 'VIRTIO',
      volume_type       => 'SSD',
      image_id          => '7412cec6-e83c-11e6-a994-525400f64d8d',
      ssh_keys          => [ 'ssh-rsa AAAAB3NzaC1yc2EAA...' ],
      availability_zone => 'AUTO'
    }
  ]
}
-> nic { 'testnic':
  datacenter_name => $datacenter_name,
  server_name     => $server_name,
  nat             => false,
  dhcp            => true,
  lan             => $lan_name,
  ips             => ['78.137.103.102', '78.137.103.103', '78.137.103.104'],
  firewall_active => true,
  firewall_rules  => [
    {
      name             => 'SSH',
      protocol         => 'TCP',
      port_range_start => 22,
      port_range_end   => 22
    },
    {
      name             => 'HTTP',
      protocol         => 'TCP',
      port_range_start => 80,
      port_range_end   => 80
    }
  ]
}

```
