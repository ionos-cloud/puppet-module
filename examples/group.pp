ionoscloud_group { 'Puppet Test' :
  ensure              => present,
  create_data_center   => false,
  create_snapshot     => false,
  reserve_ip          => true,
  access_activity_log => true,
  members             => []
}
