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


## Example

```text
datacenter { 'myDataCenter' :
  ensure              => present,
  location            => 'de/fra',
  description         => 'test data center',
  sec_auth_protection => false,
}

```