
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
},

lan { 'nou' :
  ensure          => present,
  public          => true,
  datacenter_name => 'myDataCenter2',
},

server { 'frontend2' :
  ensure => present,
  cores => 1,
  datacenter_name => 'myDataCenter2',
  ram => 1024,
  volumes => [
    {
      name => 'volume1',
      volume_type => 'SSD',
      size => 10,
      image_alias => 'debian:latest',
      image_password => 'parola123',
    },
  ],
  nics => [
    {
      name => 'private',
      dhcp => true,
      lan => 'foartenou',
      nat => false,
      firewall_active => true,
      ips => ['158.222.102.161'],
      firewall_rules => [
        { 
          name => 'SSH2',
          protocol => 'TCP',
          port_range_start => 22,
          port_range_end => 22,
        },
        { 
          name => 'HTTP2',
          protocol => 'TCP',
          port_range_start => 65,
          port_range_end => 80
        },
        { 
          name => 'ICMP2',
          protocol => 'ICMP',
          icmp_type => 123,
          icmp_code => 165,
        }
      ]
    },
  ]
},

pcc { 'noulpcc' :
  ensure => present,
  description => 'descriere',
  peers => [
    {
      name => 'lanuldeporumb',
      datacenter_name => 'myDataCenter2'
    }
  ]
},

lan { 'foartenou' :
  ensure          => present,
  public          => false,
  datacenter_name => 'myDataCenter2',
},

backup_unit { 'myBackupUnit' :
  ensure      => present,
  password    => 'parola123',
  email    => 'a2@a.com',
},

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

# firewall_rule { 'HTTP2':
#   ensure           => present,
#   datacenter_name  => 'myDataCenter2',
#   server_name      => 'frontend2',
#   nic              => 'testnic',
#   protocol         => 'TCP',
#   port_range_start => 81,
#   port_range_end   => 83,
#   source_mac       => '12:47:e9:b1:77:b4',
#   source_ip        => '10.81.12.122',
#   target_ip        => '10.81.12.126',
# },

# volume { 'testvolume' :
#   ensure            => absent,
#   datacenter_name   => 'myDataCenter2',
#   size              => 15,
#   volume_type       => 'SSD',
#   licence_type      => 'LINUX',
#   image_alias       => 'debian:latest',
#   image_password    => 'secretpassword2015',
#   availability_zone => 'AUTO',
# },

# snapshot { 'PPTestSnapshot' :
#   ensure     => present,
#   datacenter => 'myDataCenter2',
#   volume     => 'testvolume',
#   description => 'ceva',
#   restore => false,
# },

# ipblock { 'puppet_demo':
#   ensure     => present,
#   location   => 'us/ewr',
#   size       => 2
# },

# ionoscloud_user { 'john.doe.00712@example.com' :
#   ensure        => present,
#   firstname     => 'John2',
#   lastname      => 'Doe2',
#   password      => 'Secrete.Password.007',
#   administrator => false,
#   groups        => ['Puppet Module Test', 'Puppet Module Test 2'],
# },
# ionoscloud_group { 'Puppet Test 2' :
#   ensure              => present,
#   create_data_center  => true,
#   create_snapshot     => false,
#   reserve_ip          => false,
#   access_activity_log => true,
#   s3_privilege        => true,
#   create_backup_unit  => true,
#   create_internet_access => true,
#   create_k8s_cluster        => true,
#   create_pcc  => true,
#   members             => ['john.doe.0071@example.com']
# },

# share { '1ca85771-5c86-476e-b86b-803223352370' :
#   ensure          => present,
#   edit_privilege  => false,
#   share_privilege => true,
#   group_name      => 'Puppet Test 2'
# }
]
