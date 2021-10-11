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


## Example

```text
backup_unit { 'new_backup_unit' :
  ensure   => absent,
  email    => 'email@mail.com',
  password => 'secret_password',
}

```
