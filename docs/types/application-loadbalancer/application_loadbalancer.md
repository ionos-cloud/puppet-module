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


## Example

No example available
