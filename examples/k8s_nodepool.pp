$cluster_name = 'puppet_module_testa'
$datacenter_name = 'new'

k8s_nodepool { 'nodepool_test' :
  ensure            => present,
  cluster_name      => $cluster_name,
  datacenter_name   => $datacenter_name,
  k8s_version       => '1.18.5',
  maintenance_day   => 'Sunday',
  maintenance_time  => '13:53:00Z',
  node_count        => 1,
  cores_count       => 1,
  cpu_family        => 'INTEL_SKYLAKE',
  ram_size          => 2048,
  storage_type      => 'SSD',
  storage_size      => 10,
  min_node_count    => 1,
  max_node_count    => 2,
  availability_zone => 'AUTO',
  lans              => [],
  labels            => {
    test  => 'test',
    test2 => 'test'
  }
}
