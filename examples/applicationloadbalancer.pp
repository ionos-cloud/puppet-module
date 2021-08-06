$datacenter_name = 'testdc2'

datacenter { $datacenter_name :
  ensure      => present,
  location    => 'de/txl',
  description => 'my data center desc.'
}
-> application_loadbalancer { 'test_app_lb':
  datacenter_name => $datacenter_name,
  ips             => ['85.215.232.165'],
  lb_private_ips  => ['10.12.106.225/24', '10.12.106.227/24'],
  target_lan      => 2,
  listener_lan    => 1,
  rules           => [
    {
      name                => 'regula',
      protocol            => 'HTTP',
      listener_ip         => '85.215.232.165',
      listener_port       => 47,
      health_check        => {
        client_timeout  => 50000,
      },
      server_certificates => [
      ],
      http_rules          => [
        {
          name        => 'nume1',
          type        => 'REDIRECT',
          drop_query  => true,
          location    => 'www.ionos.com',
          status_code => 303,
          conditions  => [
            {
              type      => 'header',
              condition => 'starts-with',
              negate    => true,
              key       => 'forward-at',
              value     => 'Friday',
            },
          ],
        },
        {
          name             => 'nume2',
          type             => 'STATIC',
          status_code      => 303,
          response_message => 'Application Down',
          content_type     => 'text/html',
          conditions       => [
            {
              type      => 'query',
              condition => 'starts-with',
              negate    => true,
              key       => 'forward-at',
              value     => 'Friday',
            },
          ],
        },
      ]
    },
    {
      name                => 'regula2',
      protocol            => 'HTTP',
      listener_ip         => '85.215.232.165',
      listener_port       => 23,
      health_check        => {
        client_timeout  => 45000,
      },
      server_certificates => [
      ],
      http_rules          => [

      ]
    },
]
}
