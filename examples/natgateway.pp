$datacenter_name = 'testdc1'

datacenter { $datacenter_name :
  ensure      => present,
  location    => 'us/las',
  description => 'my data center desc.'
}
-> natgateway { 'testnatg':
  datacenter_name => $datacenter_name,
  public_ips      => ['127.0.0.2'],
  lans            => [
  ],
  flowlogs        => [
    {
      name      => 'test123123',
      action    => 'ALL',
      bucket    => 'testtest234134124214',
      direction => 'EGRESS',
    }
  ],
  rules           => [
    {
      name              => 'test_rule',
      protocol          => 'TCP',
      source_subnet     => '192.168.0.1/32',
      target_subnet     => '192.168.0.4/32',
      public_ip         => '127.0.0.1',
      target_port_range => {
        start => 22,
        end   => 27,
      }
    },
    {
      name              => 'test_rule2',
      protocol          => 'TCP',
      source_subnet     => '192.168.0.1/32',
      target_subnet     => '192.168.0.4/32',
      public_ip         => '127.0.0.1',
      target_port_range => {
        start => 23,
        end   => 26,
      }
    },
    {
      name              => 'test_rule3',
      protocol          => 'TCP',
      source_subnet     => '192.168.0.1/32',
      target_subnet     => '192.168.0.4/32',
      public_ip         => '127.0.0.1',
      target_port_range => {
        start => 22,
        end   => 24,
      }
    },
  ]
}
