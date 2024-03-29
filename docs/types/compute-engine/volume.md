# volume

Type representing a IonosCloud storage volume.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the volume.   |
| image_password |  | The image password for the "root" or "Administrator" account.   |
| ssh_keys |  | One or more SSH keys to allow access to the volume via SSH.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| size | No | The size of the volume in GB.   |
| image_id | No | The image or snapshot ID.   |
| availability_zone | No | The availability zone of where the volume will reside.   |
| bus | No | The bus type of the volume.  Valid values are `VIRTIO`, `IDE`.  |
| volume_type | No | The volume type.  Valid values are `HDD`.  |
| user_data | No | The cloud-init configuration for the volume as base64 encoded string. The property is immutable and is only allowed to be set on a new volume creation. It is mandatory to provide either 'public image' or 'imageAlias' that has cloud-init compatibility in conjunction with this property.   |
| licence_type | No | The license type of the volume.  Valid values are `LINUX`, `WINDOWS`, `WINDOWS2016`, `UNKNOWN`, `OTHER`.  |
| device_number | No | The LUN ID of the storage volume. Null for volumes not mounted to any VM   |
| pci_slot | No | The PCI slot number of the storage volume. Null for volumes not mounted to any VM   |
| backupunit_id | No | The uuid of the Backup Unit that user has access to. The property is immutable and is only allowed to be set on a new volume creation. It is mandatory to provide either 'public image' or 'imageAlias' in conjunction with this property.   |
| cpu_hot_plug | No | Indicates CPU hot plug capability.   |
| ram_hot_plug | No | Indicates memory hot plug capability.   |
| nic_hot_plug | No | Indicates NIC hot plug capability.   |
| nic_hot_unplug | No | Indicates NIC hot unplug capability.   |
| disc_virtio_hot_plug | No | Indicates VirtIO drive hot plug capability.   |
| disc_virtio_hot_unplug | No | Indicates VirtIO drive hot unplug capability.   |
| datacenter_id | No | The ID of the virtual data center where the volume will reside.   |
| datacenter_name | No | The name of the virtual data center where the volume will reside.   |
| id | No | The volume ID.   |
***


### Changeable properties:

* size


## Examples

### To list resources:
```bash
puppet resource volume
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
$datacenter_name = 'TestDataCenter'

datacenter { $datacenter_name :
  ensure   => present,
  location => 'us/las'
}
-> volume { 'testvolume' :
  ensure            => present,
  datacenter_name   => $datacenter_name,
  licence_type      => 'LINUX',
  size              => 50,
  volume_type       => 'SSD',
  availability_zone => 'AUTO',
  bus               => 'IDE',
  cpu_hot_plug      => true,
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

