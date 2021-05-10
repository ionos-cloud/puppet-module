backup_unit { 'new_backup_unit' :
  ensure   => absent,
  email    => 'email@mail.com',
  password => 'secret_password',
}
