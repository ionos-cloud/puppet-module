#!/usr/bin/env ruby

# This must be run from /docs directory

require 'puppet'

$LOAD_PATH << '.'

types = []
Dir["../lib/puppet/type/*.rb"].each { |file| require file; types << file.split('/')[-1].split('.')[0] }
puts types.to_s
puts Puppet::Type.type(:datacenter).doc



Puppet::Type.type(:datacenter).parameters.each do
  |param|
  param_class = Puppet::Type.type(:datacenter).paramclass(param)
  puts [param_class.name, param_class.doc, param_class.default, param_class.isrequired].to_s
end

Puppet::Type.type(:datacenter).properties.each do
  |property|
  puts [property.name, property.doc, property.default, property.required?].to_s
end

puts File.open('../examples/datacenter.pp').read
