$group_name = 'operators'

ionoscloud_group { $group_name :
  ensure              => present,
  create_data_center  => true,
  create_snapshot     => true,
  reserve_ip          => true,
  access_activity_log => false
}
-> ionoscloud_user { 'operator.abc@mydomain.org' :
  ensure        => present,
  firstname     => 'John',
  lastname      => 'Doe',
  password      => 'Secrete.Password.007',
  administrator => false,
  groups        => [$group_name]
}
