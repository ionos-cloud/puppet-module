$datacenter_name = 'testdc1'

datacenter { $datacenter_name :
  ensure      => present,
  location    => 'us/las',
  description => 'my data center desc.'
}
-> natgateway { 'testnatg':
  datacenter_name => $datacenter_name,
  public_ips      => ['158.222.103.21'],
  lans            => [
  ],
  flowlogs        => [
    {
      name      => 'test123123',
      action    => 'ALL',
      bucket    => 'testtest234134124214',
      direction => 'EGRESS',
    }
  ]
}
