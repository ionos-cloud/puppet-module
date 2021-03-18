
[
#   datacenter { 'myDataCenter' :
#   ensure      => present,
#   location    => 'us/las',
# },
#   datacenter { 'myDataCenter2' :
#   ensure      => present,
#   location    => 'us/las',
# },

# server { 'worker1' :
#   ensure => present,
#   cores => 1,
#   datacenter_name => 'myDataCenter',
#   ram => 512,
# },

# server { 'worker2' :
#   ensure => present,
#   cores => 1,
#   datacenter_name => 'myDataCenter',
#   ram => 512,
# },
# server { 'worker3' :
#   ensure => present,
#   cores => 1,
#   datacenter_name => 'myDataCenter2',
#   ram => 512,
# },
lan { 'private' :
  ensure => present,
  public => false,
  datacenter_name => 'myDataCenter2'
},
lan { 'public' :
  ensure => present,
  public => true,
  datacenter_name => 'myDataCenter2'
},

# server { 'frontend' :
#   ensure => absent,
#   datacenter_name => 'myDataCenter2',
# }

server { 'frontend' :
  ensure => present,
  cores => 2,
  datacenter_name => 'myDataCenter2',
  ram => 2048,
  volumes => [
    {
      name => 'system',
      size => 10,
      bus => 'VIRTIO',
      volume_type => 'SSD',
      image_alias => 'ubuntu:latest',
      image_password => 'secretpassword2015',
      availability_zone => 'AUTO',
    }
  ],
  nics => [
    {
      name => 'public',
      dhcp => true,
      lan => 'public',
      nat => false,
      firewall_rules => [
        { 
          name => 'SSH',
          protocol => 'TCP',
          port_range_start => 22,
          port_range_end => 22
        },
        { 
          name => 'HTTP',
          protocol => 'TCP',
          port_range_start => 80,
          port_range_end => 80
        }
      ]
    },
    {
      name => 'private',
      dhcp => true,
      lan => 'private',
      nat => false,
    }
  ]
}

# server { 'frontend' :
#   ensure => absent,
# }
# datacenter { 'myDataCenter' :
#   description => 'test nou 2 22 '
# },

# datacenter { 'myDataCenter' :
#   ensure      => absent,
# },
]
