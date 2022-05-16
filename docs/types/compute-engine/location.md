# location

Type representing a IonosCloud location.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the location.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| id | No | The ID of the location.   |
| features | No | A list of features available at the location.   |
| cpu_architecture | No | Array of features and CPU families available in a location.   |
| image_aliases | No | A list of image aliases available at the location.   |
***


### Changeable properties:

No Changeable properties


## Examples

### To list resources:
```bash
puppet resource location
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

No example available
