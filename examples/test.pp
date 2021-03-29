
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
  datacenter_name => 'myDataCenter2'
},

# server { 'frontend' :
#   ensure => absent,
#   datacenter_name => 'myDataCenter2',
# }

# server { 'frontend2' :
#   ensure => present,
#   cores => 1,
#   datacenter_name => 'myDataCenter2',
#   ram => 1024,
#   volumes => [
#     { 
#       name => 'data2',
#       size => 10,
#       bus => 'VIRTIO',
#       volume_type => 'SSD',
#       image_alias => 'ubuntu:latest',
#       image_password => 'secretpassword2015',
#       availability_zone => 'AUTO',
#     },
#   ],
#   nics => [
#     {
#       name => 'public',
#       dhcp => true,
#       lan => 'public',
#       nat => false,
#     },
#     {
#       name => 'private',
#       dhcp => false,
#       lan => 'public',
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
#           name => 'HTTP2',
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
#     }
#   ]
# },

server { 'frontend3' :
  ensure => present,
  cores => 1,
  datacenter_name => 'myDataCenter2',
  ram => 1024,
  cpu_family => 'INTEL_XEON',
  volumes => [
    { 
      id => '670397f2-c3c1-4baa-9bdd-4a280296e469'
    },
  ],
  nics => [
    {
      name => 'public',
      dhcp => true,
      lan => 'public',
      nat => false,
    },
    {
      name => 'private',
      dhcp => false,
      lan => 'public',
      nat => false,
      firewall_active => true,
      firewall_rules => [
        { 
          name => 'SSH',
          protocol => 'TCP',
          port_range_start => 22,
          port_range_end => 22,
        },
        { 
          name => 'HTTP2',
          protocol => 'TCP',
          port_range_start => 65,
          port_range_end => 80
        }
      ]
    },
    {
      name => 'private2',
      dhcp => true,
      lan => 'public',
      nat => false,
    }
  ]
},
# volume { 'testvolume' :
#   ensure            => present,
#   datacenter_name   => 'myDataCenter2',
#   size              => 11,
#   volume_type       => 'SSD',
#   image_alias       => 'ubuntu:latest',
#   image_password    => 'secretpassword2015',
#   availability_zone => 'AUTO',
# }

# server { 'frontend' :
#   ensure => absent,
#   datacenter_name => 'myDataCenter2',
# }
# datacenter { 'myDataCenter' :
#   description => 'test nou 2 22 '
# },

# datacenter { 'myDataCenter' :
#   ensure      => absent,
# },
]
