# backup_unit

Type representing a Ionoscloud Backup Unit

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | Alphanumeric name you want assigned to the backup unit.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| email | Yes | The e-mail address you want assigned to the backup unit.   |
| password | Yes | Alphanumeric password you want assigned to the backup unit.   |
| id | No | The Backup Unit ID.   |
***


### Changeable properties:

* email


## Examples

### To list resources:
```bash
puppet resource backup_unit
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
backup_unit { 'new_backup_unit' :
  ensure   => absent,
  email    => 'email@mail.com',
  password => 'secret_password',
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

