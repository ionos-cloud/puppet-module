# template

Type representing available templates for CUBE servers.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the template.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| cores | No | The CPU cores count.   |
| ram | No | The RAM size in MB.   |
| storage_size | No | The storage size in GB.   |
***


### Changeable properties:

No Changeable properties


## Examples

### To list resources:
```bash
puppet resource template
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

No example available
