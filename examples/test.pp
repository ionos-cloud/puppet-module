
[
  datacenter { 'myDataCenter' :
  ensure      => present,
  location    => 'de/fra',
},

# server { 'worker1' :
#   ensure => present,
#   cores => 4,
#   datacenter_name => 'myDataCenter',
#   ram => 512,
# },

# datacenter { 'myDataCenter' :
#   description => 'test nou 2 22 '
# },

# datacenter { 'myDataCenter' :
#   ensure      => absent,
# },
]
