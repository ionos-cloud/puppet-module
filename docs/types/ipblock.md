# ipblock

Type representing a IonosCloud IP block.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the IP block.   |

## Properties:

| Name | Required | Description | Default Value |
| :--- | :-: | :--- | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  | - |
| location | No | The IP block's location.   | - |
| size | No | The size of the IP block.   | - |
| id | No | The IP block's ID.   | - |
| created_by | No | The user who created the IP block.   | - |
| ips | No | The IPs allocated to the IP block.   | - |
| ip_consumers | No | Read-Only attribute. Lists consumption detail of an individual ip   | - |
***


### Changeable properties:

* firstname
* lastname
* administrator
* force_sec_auth
* groups


## Example

```text
ipblock { 'puppet_demo':
  ensure   => present,
  location => 'us/ewr',
  size     => 2
}

```
