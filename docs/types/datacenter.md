# datacenter

Type representing a ProfitBricks virtual data center.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the virtual data center where the server will reside.   |

## Properties:

| Name | Required | Description | Default Value |
| :--- | :-: | :--- | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  | - |
| description | No | The data center description.   | - |
| id | No | The data center ID.   | - |
| location | Yes | The data center location.   | - |
***


### Changeable properties:

* description


## Example

```text
datacenter { 'myDataCenter' :
  ensure      => present,
  location    => 'de/fra',
  description => 'test data center'
}

```
