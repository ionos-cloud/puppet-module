$datacenter_name = 'MyDataCenter'
$server_name = 'worker4'
$nic = 'testnic3'

firewall_rule { 'SSH':
  ensure           => 'present',
  datacenter_name  => 'MyDataCenter',
  nic_name         => 'testnic3',
  port_range_end   => 29,
  port_range_start => 22,
  protocol         => 'TCP',
  provider         => 'v1',
  server_name      => 'worker4',
  type             => 'INGRESS',
}
