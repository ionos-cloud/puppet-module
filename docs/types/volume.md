# volume

Type representing a IonosCloud storage volume.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the volume.   |
| image_password |  | The image password for the "root" or "Administrator" account.   |
| image_alias |  | The image alias. E.g. ubuntu:latest   |
| ssh_keys |  | One or more SSH keys to allow access to the volume via SSH.   |

## Properties:

| Name | Required | Description | Default Value |
| :--- | :-: | :--- | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  | - |
| size | No | The size of the volume in GB.   | - |
| image_id | No | The image or snapshot ID.   | - |
| availability_zone | No | The availability zone of where the volume will reside.   | AUTO |
| bus | No | The bus type of the volume.  Valid values are `VIRTIO`, `IDE`.  | VIRTIO |
| volume_type | No | The volume type.  Valid values are `HDD`, `SSD`.  | HDD |
| user_data | No | The cloud-init configuration for the volume as base64 encoded string. The property is immutable and is only allowed to be set on a new volume creation. It is mandatory to provide either 'public image' or 'imageAlias' that has cloud-init compatibility in conjunction with this property.   | - |
| licence_type | No | The license type of the volume.  Valid values are `LINUX`, `WINDOWS`, `WINDOWS2016`, `UNKNOWN`, `OTHER`.  | - |
| device_number | No | The LUN ID of the storage volume. Null for volumes not mounted to any VM   | - |
| backupunit_id | No | The uuid of the Backup Unit that user has access to. The property is immutable and is only allowed to be set on a new volume creation. It is mandatory to provide either 'public image' or 'imageAlias' in conjunction with this property.   | - |
| cpu_hot_plug | No | Indicates CPU hot plug capability.   | - |
| ram_hot_plug | No | Indicates memory hot plug capability.   | - |
| nic_hot_plug | No | Indicates NIC hot plug capability.   | - |
| nic_hot_unplug | No | Indicates NIC hot unplug capability.   | - |
| disc_virtio_hot_plug | No | Indicates VirtIO drive hot plug capability.   | - |
| disc_virtio_hot_unplug | No | Indicates VirtIO drive hot unplug capability.   | - |
| datacenter_id | No | The ID of the virtual data center where the volume will reside.   | - |
| datacenter_name | No | The name of the virtual data center where the volume will reside.   | - |
***


### Changeable properties:

* size


## Example

```text
$datacenter_name = 'TestDataCenter'

datacenter { $datacenter_name :
  ensure   => present,
  location => 'us/las'
}
-> volume { 'testvolume' :
  ensure            => present,
  datacenter_name   => $datacenter_name,
  image_alias       => 'ubuntu:latest',
  image_password    => 'password',
  size              => 50,
  volume_type       => 'SSD',
  availability_zone => 'AUTO',
  bus               => 'IDE',
  cpu_hot_plug      => true,
}

```
