$datacenter_name = 'MyDataCenter'

server { 'worker4' :
  ensure          => present,
  cores           => 1,
  datacenter_name => $datacenter_name,
  ram             => 1024,
  cpu_family      => 'INTEL_SKYLAKE',
  volumes         => [
    {
      name              => 'system',
      size              => 50,
      bus               => 'VIRTIO',
      volume_type       => 'SSD',
      licence_type      => 'LINUX',
      availability_zone => 'AUTO'
    }
  ],
  nics            => [
    {
      name            => 'testnic3',
      dhcp            => true,
      lan             => 'public',
      ips             => ['127.0.0.1'],
      firewall_active => true,
      firewall_type   => 'EGRESS',
      firewall_rules  => [
        {
          name             => 'HTTP3',
          type             => 'INGRESS',
          protocol         => 'TCP',
          port_range_start => 76,
          port_range_end   => 80
        },
        {
          name             => 'SSH',
          type             => 'INGRESS',
          protocol         => 'TCP',
          port_range_start => 22,
          port_range_end   => 27
        }
      ],
      flowlogs        => [
        {
          name      => 'test2',
          action    => 'ALL',
          bucket    => 'testtest234134124214',
          direction => 'INGRESS',
        }
      ]
    },
    {
      name            => 'testnic2',
      dhcp            => true,
      lan             => 'public',
      ips             => ['127.0.0.1'],
      firewall_active => true,
      firewall_type   => 'INGRESS',
    }
  ],
  cdroms          => [
    {
      id => '1c511436-5bfa-11ec-adcb-2e0e2737acfd',
    }
  ]
}
