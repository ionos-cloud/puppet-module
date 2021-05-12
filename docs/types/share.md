# share

Type representing a ProfitBricks shared resource.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The ID of the resource to share.   |

## Properties:

| Name | Required | Description | Default Value |
| :--- | :-: | :--- | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  | - |
| edit_privilege | No | Indicates if the group has permission to edit privileges on the resource.  Valid values are `true`, `false`.  | false |
| share_privilege | No | Indicates if the group has permission to share the resource.  Valid values are `true`, `false`.  | false |
| group_id | No | The ID of the group where the share will be available.   | - |
| group_name | No | The name of the group where the share will be available.   | - |
| type | No | The type of the shared resource.   | - |
***


### Changeable properties:

* edit_privilege
* share_privilege


## Example

```text
$datacenter_id = '4017613d-b3fb-41bd-a7bf-8da8e1b02890'

share { $datacenter_id :
  ensure          => present,
  edit_privilege  => true,
  share_privilege => true,
  group_name      => 'cli'
}
```
