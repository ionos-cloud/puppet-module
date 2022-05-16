# datacenter

Type representing a IonosCloud virtual data center.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the virtual data center where the server will reside.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| description | No | The data center description.   |
| sec_auth_protection | No | Boolean value representing if the data center requires extra protection e.g. two factor protection.  Valid values are `true`, `false`.  |
| location | Yes | The data center location.   |
| version | No | The data center version.   |
| features | No | List of features supported by the location this data center is part of.   |
| cpu_architecture | No | Array of features and CPU families available in a location.   |
| id | No | The data center ID.   |
***


### Changeable properties:

* description


## Examples

### To list resources:
```bash
puppet resource datacenter
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
datacenter { 'MyDataCenter' :
  ensure              => present,
  location            => 'de/fra',
  description         => 'test data center',
  sec_auth_protection => false,
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

