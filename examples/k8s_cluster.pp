k8s_cluster { 'myClustertest' :
  ensure                => present,
  k8s_version           => '1.18.5',
  maintenance_day       => 'Sunday',
  maintenance_time      => '14:53:00Z',
  public                => true,
  api_subnet_allow_list => [
    '1.2.3.4/32',
    '2002::1234:abcd:ffff:c0a8:101/64',
    '1.2.3.4/32',
    '2002::1234:abdd:ffff:c0a8:101/128',
  ],
  s3_buckets            => [
    {
      name => 'testtest234134124214'
    },
  ]
}
