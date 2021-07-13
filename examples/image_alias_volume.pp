$datacenter_name = 'My data center'

datacenter { $datacenter_name :
  ensure   => present,
  location => 'us/ewr'
}
-> volume { 'centos7vol' :
  ensure          => present,
  datacenter_name => $datacenter_name,
  size            => 10,
  volume_type     => 'HDD',
  ssh_keys        => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDaH...']
}
