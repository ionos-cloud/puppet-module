k8s_cluster { 'myClustertest' :
  ensure           => present,
  k8s_version      => '1.18.5',
  maintenance_day  => 'Sunday',
  maintenance_time => '14:53:00Z',
}
