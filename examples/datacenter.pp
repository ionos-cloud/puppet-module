datacenter { 'myDataCenter' :
  ensure      => present,
  location    => 'de/fra',
  description => 'test data center',
  sec_auth_protection => false,
}
