# vm_autoscaling_group

Type representing a VM Autoscaling group.

## Parameters:

| Name | Required | Description |
| :--- | :-: | :--- |
| name | true | The name of the VM Autoscaling group.   |

## Properties:

| Name | Required | Description |
| :--- | :-: | :--- |
| ensure | No | The basic property that the resource should be in.  Valid values are `present`, `absent`.  |
| target_replica_count | No | The target number of VMs in this Group. Depending on the scaling policy, this number will be adjusted automatically. VMs will be created or destroyed automatically in order to adjust the actual number of VMs to this number. If targetReplicaCount is given in the request body then it must be >= minReplicaCount and <= maxReplicaCount.   |
| min_replica_count | No | Minimum replica count value for `targetReplicaCount`. Will be enforced for both automatic and manual changes.   |
| max_replica_count | No | Maximum replica count value for `targetReplicaCount`. Will be enforced for both automatic and manual changes.   |
| replica_configuration | No | The replica configuration   |
| policy | No | Specifies the behavior of this autoscaling group. A policy consists of Triggers and Actions, whereby an Action is some kind of automated behavior, and the Trigger defines the circumstances, under which the Action is triggered. Currently, two separate Actions, namely Scaling In and Out are supported, triggered through the thresholds, defined for a given Metric.   |
| datacenter | No | VMs for this autoscaling group will be created in this virtual data center.   |
| location | Yes | The data center location.   |
| id | No | The VM Autoscaling group's ID.   |
| actions | No | A list of actions for the VM Autoscaling group.   |
| servers | No | A list of servers for the VM Autoscaling group.   |
***


### Changeable properties:

* description
* max_replica_count
* min_replica_count
* target_replica_count
* replica_configuration
* policy


## Example

```ruby
vm_autoscaling_group { 'test-autoscaling' :
    ensure                => present,
    max_replica_count     => 3,
    min_replica_count     => 1,
    target_replica_count  => 2,
    datacenter            => 'test_datacenter_autoscaling',
    location              => 'us/las',
    policy                => {
        metric              => 'INSTANCE_CPU_UTILIZATION_AVERAGE',
        range               => 'PT24H',
        scale_in_action     => {
            amount             => 1,
            amount_type        => 'ABSOLUTE',
            cooldown_period    => 'PT5M',
            termination_policy => 'RANDOM'
        },
        scale_in_threshold  => 33,
        scale_out_action    => {
            amount          => 2,
            amount_type     => 'ABSOLUTE',
            cooldown_period => 'PT5M',
        },
        scale_out_threshold => 77,
        unit                => 'PER_HOUR'
    },
    replica_configuration => {
        availability_zone => 'ZONE_1',
        cores             => 2,
        cpu_family        => 'INTEL_XEON',
        ram               => 1024,
        nics              => [
            {
                lan  => 1,
                name => 'TEST_NIC1',
                dhcp => true,
            },
            {
                lan  => 1,
                name => 'TEST_NIC22',
                dhcp => false,
            }
        ],
        volumes           => [
            {
                image          => 'cbc2fd40-6aae-11ec-a917-62772f9c5dc0',
                image_password => 'test12345',
                name           => 'SDK_TEST_VOLUME',
                size           => 50,
                type           => 'HDD',
                bus            => 'IDE',
            }
        ]
    },
}

```
