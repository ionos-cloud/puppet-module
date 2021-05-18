# server

Type representing a ProfitBricks server.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the server.   |

## Properties:

| Name | Required | Description | Default Value |
| :--- | :-: | :--- | :--- |
| ensure | No |   Valid values are `present`, `absent`, `running`, `stopped`.  | - |
| datacenter_id | No | The virtual data center where the server will reside.   | - |
| datacenter_name | No | The name of the virtual data center where the server will reside.   | - |
| cores | No | The number of CPU cores assigned to the server.   | - |
| cpu_family | No | The CPU family of the server.  Valid values are `AMD_OPTERON`, `INTEL_XEON`.  | AMD_OPTERON |
| ram | No | The amount of RAM in MB assigned to the server.   | - |
| availability_zone | No | The availability zone of where the server will reside.  Valid values are `AUTO`, `ZONE_1`, `ZONE_2`.  | AUTO |
| boot_volume | No | The boot volume name, if more than one volume it attached to the server.   | - |
| licence_type | No | The OS type of the server.  Valid values are `LINUX`, `WINDOWS`, `WINDOWS2016`, `UNKNOWN`, `OTHER`.  | - |
| nat | No | A boolean which indicates if the NIC will perform Network Address Translation.   | false |
| volumes | No | A list of volumes to associate with the server.   | - |
| cdroms | No | A list of Cdroms to associate with the server.   | - |
| purge_volumes | No | Sets whether attached volumes are removed when server is removed.  Valid values are `true`, `false`.  | false |
| nics | No | A list of network interfaces associated with the server.   | - |
***


### Changeable properties:

* cores
* cpu_family
* ram
* availability_zone
* boot_volume
* volumes
* nics


## Example

```text
$datacenter_name = 'TestDataCenter'

server { 'worker1' :
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
      image_alias       => 'debian:latest',
      image_password    => 'password',
      availability_zone => 'AUTO'
    }
  ],
  cdroms         => [
    {
      id => '154011c9-9576-11e8-af82-525400f64d8d',
    }
  ],
  nics            => [
    {
      name           => 'public',
      dhcp           => true,
      lan            => 'public',
      nat            => false,
      firewall_rules => [
        {
          name             => 'SSH',
          protocol         => 'TCP',
          port_range_start => 22,
          port_range_end   => 22
        }
      ]
    }
  ]
}

```
