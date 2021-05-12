require 'puppet'

$LOAD_PATH << '.'
Dir["../lib/puppet/type/*.rb"].each { |file| require file; puts file; }

puts Puppet::Type.type(:lan)
