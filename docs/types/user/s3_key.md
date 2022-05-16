# s3_key

Type representing an s3 key

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The id of the s3 key.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| user_id | No | The ID of the user.   |
| user_email | No | The email of the user.   |
| secret_key | No | The secret key.   |
| active | No | The ID of the user.  Valid values are `true`, `false`.  |
***


### Changeable properties:

No Changeable properties


## Examples

### To list resources:
```bash
puppet resource s3_key
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

No example available
