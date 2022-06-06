# image

Type representing a IonosCloud image.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the image.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| id | No | The ID of the image.   |
| description | No | The image's description.   |
| location | No | The image's location.   |
| size | No | The size of the image in GB.   |
| cpu_hot_plug | No | Indicates CPU hot plug capability.   |
| cpu_hot_unplug | No | Indicates CPU hot unplug capability.   |
| ram_hot_plug | No | Indicates memory hot plug capability.   |
| ram_hot_unplug | No | Indicates memory hot unplug capability.   |
| nic_hot_plug | No | Indicates NIC hot plug capability.   |
| nic_hot_unplug | No | Indicates NIC hot unplug capability.   |
| disc_virtio_hot_plug | No | Indicates VirtIO drive hot plug capability.   |
| disc_virtio_hot_unplug | No | Indicates VirtIO drive hot unplug capability.   |
| disc_scsi_hot_plug | No | Indicates SCSI drive hot plug capability.   |
| disc_scsi_hot_unplug | No | Indicates SCSI drive hot unplug capability.   |
| cloud_init | No | Indicates Cloud init compatibility.   |
| public | No | Indicates if the image is part of the public repository.   |
| image_type | No | The type of image.   |
| licence_type | No | The license type of the image.   |
| image_aliases | No | A list of image aliases available at the image.   |
***


### Changeable properties:

No Changeable properties


## Examples

### To list resources:
```bash
puppet resource image
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

No example available
