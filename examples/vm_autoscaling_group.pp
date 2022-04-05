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
