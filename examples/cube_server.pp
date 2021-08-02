$datacenter_name = 'testare'

server { 'worker1' :
  ensure          => suspended,
  type            => 'CUBE',
  datacenter_name => $datacenter_name,
  cpu_family      => 'INTEL_SKYLAKE',
  template_uuid   => '15c6dd2f-02d2-4987-b439-9a58dd59ecc3',
  volumes         => [
    {
      name         => 'system',
      bus          => 'VIRTIO',
      volume_type  => 'DAS',
      licence_type => 'LINUX',
    }
  ]
}
