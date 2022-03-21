target_group { 'puppet_module_test6f2nfctjrfqwfpmpamvpsjfewqfwqfqfwqd':
ensure              => absent,
  algorithm         => 'LEAST_CONNECTION',
  protocol          => 'HTTP',
  health_check      => {
    check_timeout  => 60,
    check_interval => 1400,
    retries        => 3,
  },
  http_health_check => {
    match_type => 'STATUS_CODE',
    response   => '202',
    path       => '/.',
    method     => 'GET',
  },
  targets           => [
    {
      ip                   => '1.1.1.1',
      weight               => 15,
      port                 => 20,
      health_check_enabled => true,
      maintenance_enabled  => false,
    },
    {
      ip                   => '1.1.2.2',
      weight               => 10,
      port                 => 24,
      health_check_enabled => true,
      maintenance_enabled  => true,
    },
  ],
}
