$datacenter_name = 'testare'

server { 'worker4' :
  ensure          => stopped,
  cores           => 2,
  datacenter_name => $datacenter_name,
  ram             => 1024,
  cpu_family      => 'INTEL_SKYLAKE',
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
