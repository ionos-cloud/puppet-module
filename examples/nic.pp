$datacenter_name = 'testdc1'
$server_name = 'worker1'
$lan_name = 'public1'

datacenter { $datacenter_name :
  ensure      => present,
  location    => 'us/las',
  description => 'my data center desc.'
}
-> lan { $lan_name :
  ensure          => present,
  public          => true,
  datacenter_name => $datacenter_name
}
-> server { $server_name :
  ensure          => present,
  cores           => 2,
  datacenter_name => $datacenter_name,
  ram             => 1024,
  volumes         => [
    {
      name              => 'system',
      size              => 50,
      bus               => 'VIRTIO',
      volume_type       => 'SSD',
      licence_type      => 'LINUX',
      availability_zone => 'AUTO'
    }
  ]
}
-> nic { 'testnic':
  datacenter_name => $datacenter_name,
  server_name     => $server_name,
  dhcp            => true,
  lan             => $lan_name,
  ips             => ['158.222.102.129'],
  firewall_active => true,
  firewall_type   => 'EGRESS',
  firewall_rules  => [
    {
      name             => 'SSH',
      protocol         => 'TCP',
      port_range_start => 22,
      port_range_end   => 22
    },
    {
      name             => 'HTTP',
      type             => 'INGRESS',
      protocol         => 'TCP',
      port_range_start => 80,
      port_range_end   => 80
    }
  ]
}
