$datacenter_name = 'TestDataCenter'

server { 'worker1' :
  ensure          => present,
  cores           => 2,
  datacenter_name => $datacenter_name,
  ram             => 1024,
  volumes         => [
    {
      name              => 'system',
      size              => 50,
      bus               => 'VIRTIO',
      volume_type       => 'SSD',
      image_alias       => 'debian:latest',
      image_password    => 'password',
      availability_zone => 'AUTO'
    }
  ],
  cdroms         => [
    {
      id => '154011c9-9576-11e8-af82-525400f64d8d',
    }
  ],
  nics            => [
    {
      name           => 'public',
      dhcp           => true,
      lan            => 'public',
      nat            => false,
      firewall_rules => [
        {
          name             => 'SSH',
          protocol         => 'TCP',
          port_range_start => 22,
          port_range_end   => 22
        }
      ]
    }
  ]
}
