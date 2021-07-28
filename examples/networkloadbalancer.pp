$datacenter_name = 'testdc1'

datacenter { $datacenter_name :
  ensure      => present,
  location    => 'us/las',
  description => 'my data center desc.'
}
-> networkloadbalancer { 'testnetlb':
  datacenter_name => $datacenter_name,
  ips             => ['158.222.102.243'],
  lb_private_ips  => ['10.12.106.225/24', '10.12.106.222/24'],
  target_lan      => 3,
  listener_lan    => 1,
  flowlogs        => [
    {
      name      => 'test123123',
      action    => 'ALL',
      bucket    => 'testtest234134124214',
      direction => 'INGRESS',
    }
  ],
  rules           => [
    name          => 'regula',
    algorithm     => 'ROUND_ROBIN',
    protocol      => 'TCP',
    listener_ip   => '158.222.102.243',
    listener_port => 22,
    health_check  => {
      clientTimeout  => 50000,
      connectTimeout => 5001,
      targetTimeout  => 50000,
      retries        => 3
    },
    targets       =>[
      ip          => '1.1.1.1',
      port        => 22,
      weight      => 1,
      healthCheck => {
        check         => true,
        checkInterval => 2000,
        maintenance   => false,
      },
    ],
]
}