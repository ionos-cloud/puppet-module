$datacenter_name = 'testdc3'
$lan_name = 'test1'

datacenter { $datacenter_name :
  ensure      => present,
  location    => 'de/txl',
  description => 'my data center desc.'
}
-> lan { $lan_name :
  ensure          => present,
  public          => false,
  datacenter_name => $datacenter_name
}
-> application_loadbalancer { 'test_app_lb':
  ensure          => present,
  datacenter_name => $datacenter_name,
  ips             => ['192.168.0.13'],
  lb_private_ips  => ['10.12.106.226/24', '10.12.106.227/24'],
  target_lan      => 2,
  listener_lan    => 1,
  rules           => [
    {
      name                => 'regula',
      protocol            => 'HTTP',
      listener_ip         => '192.168.0.13',
      listener_port       => 47,
      client_timeout      => 50000,
      server_certificates => [
      ],
      http_rules          => [
        {
          name        => 'nume1',
          type        => 'REDIRECT',
          drop_query  => true,
          location    => 'www.ionos.com',
          status_code => 307,
          conditions  => [
            {
              type      => 'HEADER',
              condition => 'STARTS_WITH',
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
              type      => 'QUERY',
              condition => 'STARTS_WITH',
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
      listener_ip         => '192.168.0.13',
      listener_port       => 15,
      client_timeout      => 45000,
      server_certificates => [
      ],
      http_rules          => [

      ]
    },
  ]
}
