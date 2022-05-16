# ionoscloud_user

Type representing a IonosCloud user.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| email | true | The user's e-mail address.   |
| password |  | A password for the user.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| firstname | No | The user's first name.   |
| lastname | No | The user's last name.   |
| administrator | No | Indicates whether or not the user have administrative rights.  Valid values are `true`, `false`.  |
| force_sec_auth | No | Indicates if secure (two-factor) authentication should be forced for the user.  Valid values are `true`, `false`.  |
| groups | No | The ionoscloud groups the user is assigned to.   |
| id | No | The user ID.   |
| sec_auth_active | No | Indicates if secure (two-factor) authentication is active for the user.  Valid values are `true`, `false`.  |
***


### Changeable properties:

* firstname
* lastname
* administrator
* force_sec_auth
* groups


## Examples

### To list resources:
```bash
puppet resource ionoscloud_user
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
ionoscloud_user { 'john.doe.007@example.com' :
  ensure        => present,
  firstname     => 'John',
  lastname      => 'Doe',
  password      => 'Secrete.Password.007',
  administrator => true
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

