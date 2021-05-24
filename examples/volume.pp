$datacenter_name = 'TestDataCenter'

datacenter { $datacenter_name :
  ensure   => present,
  location => 'us/las'
}
-> volume { 'testvolume' :
  ensure            => present,
  datacenter_name   => $datacenter_name,
  image_alias       => 'ubuntu:latest',
  image_password    => 'password',
  size              => 50,
  volume_type       => 'SSD',
  availability_zone => 'AUTO',
  bus               => 'IDE',
  cpu_hot_plug      => true,
}
