$datacenter_name = 'MyDataCenter'

lan { 'public' :
  ensure          => present,
  public          => true,
  datacenter_name => $datacenter_name
}
