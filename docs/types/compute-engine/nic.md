# nic

Type representing a IonosCloud network interface.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the NIC.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| ips | No | The IPs assigned to the NIC.   |
| dhcp | No | Enable or disable DHCP on the NIC.  Valid values are `true`, `false`.  |
| lan | No | The LAN name the NIC will sit on.   |
| firewall_rules | No | A list of firewall rules associated to the NIC.   |
| flowlogs | No | A list of flow logs associated to the NIC.   |
| firewall_active | No | Indicates the firewall is active.  Valid values are `true`, `false`.  |
| firewall_type | No | Indicates the firewall is active.   |
| device_number | No | The LUN ID of the storage volume. Null for volumes not mounted to any VM   |
| pci_slot | No | The PCI slot number of the storage volume. Null for volumes not mounted to any VM   |
| server_id | No | The server ID the NIC will be attached to.   |
| server_name | No | The server name the NIC will be attached to.   |
| datacenter_id | No | The ID of the virtual data center where the NIC will reside.   |
| datacenter_name | No | The name of the virtual data center where the NIC will reside.   |
| id | No | The NIC ID.   |
***


### Changeable properties:

* ips
* lan
* dhcp
* firewall_active
* firewall_rules
* firewall_type
* flowlogs


## Examples

### To list resources:
```bash
puppet resource nic
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
$datacenter_name = 'testdc1'
$server_name = 'worker1'
$lan_name = 'public1'

datacenter { $datacenter_name :
  ensure      => present,
  location    => 'us/las',
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
      licence_type      => 'LINUX',
      availability_zone => 'AUTO'
    }
  ]
}
-> nic { 'testnic':
  datacenter_name => $datacenter_name,
  server_name     => $server_name,
  dhcp            => true,
  lan             => $lan_name,
  ips             => ['127.0.0.1'],
  firewall_active => true,
  firewall_type   => 'INGRESS',
  firewall_rules  => [
    {
      name             => 'SSH',
      type             => 'INGRESS',
      protocol         => 'TCP',
      port_range_start => 22,
      port_range_end   => 27
    },
    {
      name             => 'HTTP3',
      type             => 'INGRESS',
      protocol         => 'TCP',
      port_range_start => 76,
      port_range_end   => 80
    }
  ],
  flowlogs        => [
    {
      name      => 'test2',
      action    => 'ALL',
      bucket    => 'testtest234134124214',
      direction => 'INGRESS',
    }
  ]
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

