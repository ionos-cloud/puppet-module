$datacenter_name = 'testdc1'

postgres_cluster { 'test_cluster' :
  ensure          => present,
  cores           => 1,
  datacenter_name => $datacenter_name,
  ram             => 1024,
  cpu_family      => 'INTEL_XEON',
  volumes         => [
    {
      name              => 'system',
      size              => 50,
      bus               => 'VIRTIO',
      volume_type       => 'SSD',
      licence_type      => 'LINUX',
      availability_zone => 'AUTO'
    }
  ],
}
