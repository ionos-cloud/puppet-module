# snapshot

Type representing a IonosCloud Snapshot.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the snapshot.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| restore | No | If true, restore the snapshot onto the volume specified be the volume property.  Valid values are `true`, `false`.  |
| datacenter | No | The ID or name of the virtual data center where the volume resides.   |
| volume | No | The ID or name of the volume used to create/restore the snapshot.   |
| description | No | The snapshot's description.   |
| sec_auth_protection | No | Flag representing if extra protection is enabled on snapshot e.g. Two Factor protection etc.  Valid values are `true`, `false`.  |
| licence_type | No | The OS type of this Snapshot  Valid values are `LINUX`, `WINDOWS`, `WINDOWS2016`, `UNKNOWN`, `OTHER`.  |
| cpu_hot_plug | No | Indicates CPU hot plug capability.  Valid values are `true`, `false`.  |
| cpu_hot_unplug | No | Indicates CPU hot unplug capability.  Valid values are `true`, `false`.  |
| ram_hot_plug | No | Indicates memory hot plug capability.  Valid values are `true`, `false`.  |
| ram_hot_unplug | No | Indicates memory hot unplug capability.  Valid values are `true`, `false`.  |
| nic_hot_plug | No | Indicates NIC hot plug capability.  Valid values are `true`, `false`.  |
| nic_hot_unplug | No | Indicates NIC hot unplug capability.  Valid values are `true`, `false`.  |
| disc_virtio_hot_plug | No | Indicates VirtIO drive hot plug capability.  Valid values are `true`, `false`.  |
| disc_virtio_hot_unplug | No | Indicates VirtIO drive hot unplug capability.  Valid values are `true`, `false`.  |
| disc_scsi_hot_plug | No | Indicates SCSI drive hot plug capability.  Valid values are `true`, `false`.  |
| disc_scsi_hot_unplug | No | Indicates SCSI drive hot unplug capability.  Valid values are `true`, `false`.  |
| id | No | The snapshot's ID.   |
| location | No | The snapshot's location.   |
| size | No | The size of the snapshot in GB.   |
***


### Changeable properties:

* description
* cpu_hot_plug
* cpu_hot_unplug
* ram_hot_plug
* ram_hot_unplug
* nic_hot_plug
* nic_hot_unplug
* disc_virtio_hot_plug
* disc_virtio_hot_unplug
* disc_scsi_hot_plug
* disc_scsi_hot_unplug
* sec_auth_protection
* licence_type


## Example

```ruby
$datacenter_name = 'PPSnapshotTest'
$volume_name = 'staging'

datacenter { $datacenter_name :
  ensure   => present,
  location => 'us/ewr'
}
-> volume { $volume_name :
  ensure          => present,
  datacenter_name => $datacenter_name,
  size            => 10,
  volume_type     => 'HDD',
  ssh_keys        => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDaH...']
}
-> snapshot { 'PPTestSnapshot' :
  ensure     => present,
  datacenter => $datacenter_name,
  volume     => $volume_name
}

```
