
# [
#   datacenter { 'myDataCenterPcc1' :
#   ensure      => absent,
#   location    => 'us/las',
# },
#   datacenter { 'myDataCenterPcc2' :
#   ensure      => absent,
#   location    => 'us/las',
# },
# lan { 'private' :
#   ensure => absent,
#   public => false,
#   datacenter_name => 'myDataCenterPcc1',
#   pcc => 'newpcc',
# },
# lan { 'private2' :
#   ensure => absent,
#   public => false,
#   datacenter_name => 'myDataCenterPcc1',
#   pcc => 'nil',
# },
# lan { 'private3' :
#   ensure => absent,
#   public => false,
#   datacenter_name => 'myDataCenterPcc2',
#   pcc => 'nil',
# },
# pcc { 'newpcc' :
#   ensure => absent,
#   description => 'descriere',
  # peers => [
  #   {
  #     name => 'private',
  #     datacenter_name => 'myDataCenterPcc1'
  #   },
  #   {
  #     name => 'private2',
  #     datacenter_name => 'myDataCenterPcc1'
  #   },
  # ]
# },
# ]
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
k8s_cluster { 'myCluster' :
  ensure      => present,
  k8s_version    => '1.18.15',
  maintenance_day    => 'Sunday',
  maintenance_time    => '14:53:00Z',
},
k8s_nodepool { 'nodepool_test' :
  cluster_name => 'test',
  datacenter_name => 'myDataCenter2',
  ensure      => present,
  k8s_version    => '1.18.15',
  maintenance_day    => 'Sunday',
  maintenance_time    => '13:53:00Z',
  node_count    => 1,
  cores_count    => 1,
  cpu_family    => 'INTEL_XEON',
  ram_size  => 2048,
  storage_type    => 'SSD',
  storage_size    => 10,
  min_node_count    => 1,
  max_node_count    => 1,
  availability_zone => 'AUTO',
},

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
