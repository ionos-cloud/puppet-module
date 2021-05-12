k8s_cluster { 'myCluster' :
  ensure           => present,
  k8s_version      => '1.18.15',
  maintenance_day  => 'Sunday',
  maintenance_time => '14:53:00Z',
}