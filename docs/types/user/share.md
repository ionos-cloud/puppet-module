# share

Type representing a IonosCloud shared resource.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The ID of the resource to share.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| edit_privilege | No | Indicates if the group has permission to edit privileges on the resource.  Valid values are `true`, `false`.  |
| share_privilege | No | Indicates if the group has permission to share the resource.  Valid values are `true`, `false`.  |
| group_id | No | The ID of the group where the share will be available.   |
| group_name | No | The name of the group where the share will be available.   |
| type | No | The type of the shared resource.   |
***


### Changeable properties:

* edit_privilege
* share_privilege


## Examples

### To list resources:
```bash
puppet resource share
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
$datacenter_id = '4017613d-b3fb-41bd-a7bf-8da8e1b02890'

share { $datacenter_id :
  ensure          => present,
  edit_privilege  => true,
  share_privilege => true,
  group_name      => 'cli'
}
```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

