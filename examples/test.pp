
[
  datacenter { 'myDataCenter2' :
  ensure      => present,
  location    => 'us/las',
},
lan { 'private' :
  ensure => present,
  public => false,
  datacenter_name => 'myDataCenter2'
},
lan { 'public' :
  ensure => present,
  public => true,
  datacenter_name => 'myDataCenter2',
  ip_failover     => [
    {
      ip       => '158.222.102.164',
      nic_uuid => '72da5fe4-734a-4580-8ba9-fdb950de87a6'
    },
    {
      ip       => '158.222.102.161',
      nic_uuid => '72da5fe4-734a-4580-8ba9-fdb950de87a6'
    },
  ]
},

lan { 'nou' :
  ensure          => present,
  public          => true,
  datacenter_name => 'myDataCenter2',
},

# server { 'frontend2' :
#   ensure => present,
#   cores => 1,
#   datacenter_name => 'myDataCenter2',
#   ram => 1024,
#   boot_volume => 'f85e24a8-990e-49f9-a5d3-dc86a3f9ecc3',
#   volumes => [
#     { 
#       id => 'f85e24a8-990e-49f9-a5d3-dc86a3f9ecc3',
#     },
#     {
#       id => 'cbdd58f9-8fa6-4fa8-80b9-e74e1b7b9391',
#     }
#   ],
#   nics => [
#     {
#       name => 'public',
#       dhcp => true,
#       lan => 'private',
#       nat => false,
#     },
#     {
#       name => 'private',
#       dhcp => true,
#       lan => 'private',
#       nat => false,
#       firewall_active => true,
#       firewall_rules => [
#         { 
#           name => 'SSH',
#           protocol => 'TCP',
#           port_range_start => 22,
#           port_range_end => 22,
#         },
#         { 
#           name => 'HTTP',
#           protocol => 'TCP',
#           port_range_start => 65,
#           port_range_end => 80
#         }
#       ]
#     },
#     {
#       name => 'private2',
#       dhcp => true,
#       lan => 'public',
#       nat => false,
#       ips => ['158.222.102.161', '158.222.102.164'],
#     }
#   ]
# },

# nic { 'testnic':
#   ensure          => present,
#   datacenter_name   => 'myDataCenter2',
#   server_name => 'frontend2',
#   nat => false,
#   dhcp => true,
#   lan => 'public',
#   firewall_active => true,
#   firewall_rules => [
#     { 
#       name => 'SSH',
#       protocol => 'TCP',
#       port_range_start => 22,
#       port_range_end => 22
#     },
#     { 
#       name => 'HTTP',
#       protocol => 'TCP',
#       port_range_start => 78,
#       port_range_end => 80
#     },
#   ]
# },

firewall_rule { 'HTTP2':
  ensure           => present,
  datacenter_name  => 'myDataCenter2',
  server_name      => 'frontend2',
  nic              => 'testnic',
  protocol         => 'TCP',
  port_range_start => 81,
  port_range_end   => 83,
  source_mac       => '12:47:e9:b1:77:b4',
  source_ip        => '10.81.12.122',
  target_ip        => '10.81.12.126',
},

volume { 'testvolume' :
  ensure            => present,
  datacenter_name   => 'myDataCenter2',
  size              => 15,
  volume_type       => 'SSD',
  licence_type      => 'LINUX',
  image_alias       => 'windows:2012r2',
  image_password    => 'secretpassword2015',
  availability_zone => 'AUTO',
},
ipblock { 'puppet_demo':
  ensure     => present,
  location   => 'us/ewr',
  size       => 2
}


]
