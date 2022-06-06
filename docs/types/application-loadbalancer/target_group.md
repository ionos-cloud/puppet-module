# target_group

Type representing a IonosCloud Target Group.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the Target Group.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| algorithm | No | Algorithm for the balancing.   |
| protocol | No | Protocol of the balancing.   |
| health_check | No | Health check attributes for Target Group.   |
| http_health_check | No | Http health check attributes for Target Group.   |
| targets | No | Array of targets of the Target Group.   |
| id | No | The Target Group ID.   |
***


### Changeable properties:

* algorithm
* protocol
* health_check
* http_health_check
* targets


## Examples

### To list resources:
```bash
puppet resource target_group
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
target_group { 'puppet_module_test6f2nfctjrfqwfpmpamvpsjfewqfwqfqfwqd':
ensure              => absent,
  algorithm         => 'LEAST_CONNECTION',
  protocol          => 'HTTP',
  health_check      => {
    check_timeout  => 60,
    check_interval => 1400,
    retries        => 3,
  },
  http_health_check => {
    match_type => 'STATUS_CODE',
    response   => '202',
    path       => '/.',
    method     => 'GET',
  },
  targets           => [
    {
      ip                   => '1.1.1.1',
      weight               => 15,
      port                 => 20,
      health_check_enabled => true,
      maintenance_enabled  => false,
    },
    {
      ip                   => '1.1.2.2',
      weight               => 10,
      port                 => 24,
      health_check_enabled => true,
      maintenance_enabled  => true,
    },
  ],
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

