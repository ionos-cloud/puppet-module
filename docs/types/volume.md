# volume

Type representing a ProfitBricks storage volume.

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
  ensure          => present,
  datacenter_name => $datacenter_name,
  image_id        => 'adf0c2e4-e83b-11e6-a994-525400f64d8d',
  size            => 50,
  volume_type     => 'SSD',
  ssh_keys        => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDaH...']
}

```
