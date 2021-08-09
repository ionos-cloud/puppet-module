target_group { 'test_target_group':
  algorithm         => 'LEAST_CONNECTION',
  protocol          => 'HTTP',
  health_check      => {
    check_timeout   => 60,
    connect_timeout => 4000,
    target_timeout  => 50000,
    retries         => 3,
  },
  http_health_check => {
    match_type => 'STATUS_CODE',
    response   => '200',
    path       => '/.',
    method     => 'GET',
  },
  targets           => [
    {
      ip           => '1.1.1.1',
      weight       => 15,
      port         => 20,
      health_check => {
        check          => true,
        check_interval => 2000,
        maintenance    => false,
      }
    },
  ],
}
