$datacenter_name = 'testdc1'
$lan_name = 1

postgres_cluster { 'test_cluster' :
  ensure               => present,
  restore              => false,
  instances            => 1,
  postgres_version     => '12',
  cores_count          => 1,
  ram_size             => 2048,
  storage_size         => 20490,
  storage_type         => 'HDD',
  synchronization_mode => 'ASYNCHRONOUS',
  location             => 'de/fra',
  connections          => [
    'datacenter'       => $datacenter_name,
    'lan'              => $lan_name,
    'cidr'             => '192.168.1.106/24',
  ],
  db_username          => 'test',
  db_password          => '7357cluster',
}
