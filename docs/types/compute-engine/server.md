# server

Type representing a IonosCloud server.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the server.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No |   Valid values are `present`, `absent`, `running`, `stopped`, `suspended`.  |
| type | No | The type of the server.  Valid values are `ENTERPRISE`, `CUBE`.  |
| template_uuid | No | The template UUID of the server, needed for a CUBE server.   |
| datacenter_id | No | The virtual data center where the server will reside.   |
| datacenter_name | No | The name of the virtual data center where the server will reside.   |
| cores | No | The number of CPU cores assigned to the server.   |
| cpu_family | No | The CPU family of the server.  Valid values are `AMD_OPTERON`, `INTEL_XEON`, `INTEL_SKYLAKE`.  |
| ram | No | The amount of RAM in MB assigned to the server.   |
| availability_zone | No | The availability zone of where the server will reside.  Valid values are `AUTO`, `ZONE_1`, `ZONE_2`.  |
| boot_volume | No | The boot volume name, if more than one volume it attached to the server.   |
| licence_type | No | The OS type of the server.  Valid values are `LINUX`, `WINDOWS`, `WINDOWS2016`, `UNKNOWN`, `OTHER`.  |
| volumes | No | A list of volumes to associate with the server.   |
| cdroms | No | A list of Cdroms to associate with the server.   |
| purge_volumes | No | Sets whether attached volumes are removed when server is removed.  Valid values are `true`, `false`.  |
| nics | No | A list of network interfaces associated with the server.   |
| id | No | The server ID.   |
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
$datacenter_name = 'testdc1'

server { 'worker4' :
  ensure          => present,
  cores           => 1,
  datacenter_name => $datacenter_name,
  ram             => 1024,
  cpu_family      => 'INTEL_XEON',
  volumes         => [
    {
      name              => 'system',
      size              => 50,
      bus               => 'VIRTIO',
      volume_type       => 'SSD',
      licence_type      => 'LINUX',
      availability_zone => 'AUTO'
    }
  ],
  nics            => [
    {
      name            => 'testnic3',
      dhcp            => true,
      lan             => 'public1',
      ips             => ['158.222.102.242'],
      firewall_active => true,
      firewall_type   => 'EGRESS',
      firewall_rules  => [
        {
          name             => 'HTTP3',
          type             => 'INGRESS',
          protocol         => 'TCP',
          port_range_start => 76,
          port_range_end   => 80
        },
        {
          name             => 'SSH',
          type             => 'INGRESS',
          protocol         => 'TCP',
          port_range_start => 22,
          port_range_end   => 27
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
    },
    {
      name            => 'testnic2',
      dhcp            => true,
      lan             => 'public1',
      ips             => ['158.222.102.246'],
      firewall_active => true,
      firewall_type   => 'INGRESS',
    }
  ],
  cdroms          => [
    {
      id => 'cd963010-d348-11eb-ae0d-de68fed054b6',
    }
  ]
}

```
