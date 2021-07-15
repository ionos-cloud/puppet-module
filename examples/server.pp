$datacenter_name = 'testdc1'

server { 'worker4' :
  ensure          => present,
  cores           => 1,
  datacenter_name => $datacenter_name,
  ram             => 1024,
  cpu_family      => 'INTEL_XEON',
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
      lan             => 'public1',
      ips             => ['158.222.102.242'],
      firewall_active => true,
      firewall_type   => 'EGRESS',
      firewall_rules  => [
        {
          name             => 'SSH',
          type             => 'INGRESS',
          protocol         => 'TCP',
          port_range_start => 22,
          port_range_end   => 27
        },
        {
          name             => 'HTTP3',
          type             => 'INGRESS',
          protocol         => 'TCP',
          port_range_start => 76,
          port_range_end   => 80
        }
      ]
    },
    {
      name            => 'testnic2',
      dhcp            => true,
      lan             => 'public1',
      ips             => ['158.222.102.246'],
      firewall_active => true,
      firewall_type   => 'INGRESS',
    }
  ],
  cdroms          => [
    {
      id => 'cd963010-d348-11eb-ae0d-de68fed054b6',
    }
  ]
}
