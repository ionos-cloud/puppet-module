$datacenter_name = 'TestDataCenter'

datacenter { $datacenter_name :
  ensure   => present,
  location => 'us/las'
}
-> volume { 'testvolume' :
  ensure            => present,
  datacenter_name   => $datacenter_name,
  licence_type      => 'LINUX',
  size              => 50,
  volume_type       => 'SSD',
  availability_zone => 'AUTO',
  bus               => 'IDE',
  cpu_hot_plug      => true,
}
