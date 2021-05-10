$datacenter1_name = 'datacenter1_name'
$private_lan_in_datacenter1 = 'private_lan_in_datacenter1'
$datacenter2_name = 'datacenter1_name'
$private_lan_in_datacenter2 = 'private_lan_in_datacenter2'

pcc { 'newpcc' :
  ensure      => absent,
  description => 'descriere',
  peers       => [
    {
      name            => $private_lan_in_datacenter1,
      datacenter_name => $datacenter1_name,
    },
    {
      name            => $private_lan_in_datacenter2,
      datacenter_name => $datacenter2_name,
    },
  ]
},
