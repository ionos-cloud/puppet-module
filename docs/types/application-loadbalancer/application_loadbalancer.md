# application_loadbalancer

Type representing a IonosCloud Application Load Balancer.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the Application Load Balancer.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| listener_lan | No | Id of the listening LAN. (inbound)   |
| ips | No | Collection of IP addresses of the Application Load Balancer. (inbound and outbound) IP of the listenerLan must be a customer reserved IP for the public load balancer and private IP for the private load balancer.   |
| target_lan | No | Id of the balanced private target LAN. (outbound)   |
| lb_private_ips | No | Collection of private IP addresses with subnet mask of the Application Load Balancer. IPs must contain valid subnet mask. If user will not provide any IP then the system will generate one IP with /24 subnet.   |
| rules | No | A list of flow logs associated to the Application Load Balancer.   |
| datacenter_id | No | The ID of the virtual data center where the Application Load Balancer will reside.   |
| datacenter_name | No | The name of the virtual data center where the Application Load Balancer will reside.   |
| id | No | The Application Load Balancer ID.   |
***


### Changeable properties:

* public_ips
* lans
* rules
* flowlogs


## Examples

### To list resources:
```bash
puppet resource application_loadbalancer
```
> **_NOTE:_** If two resources have the same name only one of them will be shown.


### To create, update or delete a resource:

```ruby
$datacenter_name = 'testdc3'
$lan_name = 'test1'

datacenter { $datacenter_name :
  ensure      => present,
  location    => 'de/fkb',
  description => 'my data center desc.'
}
-> lan { $lan_name :
  ensure          => present,
  public          => true,
  datacenter_name => $datacenter_name
}
-> application_loadbalancer { 'test_app_lb':
  ensure          => absent,
  datacenter_name => $datacenter_name,
  ips             => ['87.106.0.196'],
  lb_private_ips  => ['10.12.106.226/24', '10.12.106.227/24'],
  target_lan      => 2,
  listener_lan    => 1,
  rules           => [
    {
      name                => 'regula',
      protocol            => 'HTTP',
      listener_ip         => '87.106.0.196',
      listener_port       => 47,
      client_timeout      => 50000,
      server_certificates => [
      ],
      http_rules          => [
        {
          name        => 'nume1',
          type        => 'REDIRECT',
          drop_query  => true,
          location    => 'www.ionos.com',
          status_code => 307,
          conditions  => [
            {
              type      => 'HEADER',
              condition => 'STARTS_WITH',
              negate    => true,
              key       => 'forward-at',
              value     => 'Friday',
            },
          ],
        },
        {
          name             => 'nume2',
          type             => 'STATIC',
          status_code      => 303,
          response_message => 'Application Down',
          content_type     => 'text/html',
          conditions       => [
            {
              type      => 'QUERY',
              condition => 'STARTS_WITH',
              negate    => true,
              key       => 'forward-at',
              value     => 'Friday',
            },
          ],
        },
      ]
    },
    {
      name                => 'regula2',
      protocol            => 'HTTP',
      listener_ip         => '87.106.0.196',
      listener_port       => 15,
      client_timeout      => 45000,
      server_certificates => [
      ],
      http_rules          => [

      ]
    },
  ]
}

```
> **_NOTE:_** If two resources with the same name ar found an error will be thrown, this only applies to cases where the resource cannot be identified. Example: an error is thrown for two servers with the same name in the same datacenter, not for two servers with the same name, but in different datacenters.

