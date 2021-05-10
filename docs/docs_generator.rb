#!/usr/bin/env ruby

# This must be run from /docs directory

require 'mustache'
require 'puppet'

$LOAD_PATH << '.'


class Type < Mustache
  self.template_path = './templates'
  self.template_file = './templates/type_doc.mustache'

  attr_accessor :description, :name, :parameters, :properties, :example, :changeable_properties

  def initialize(name, description, parameters, properties, example, changeable_properties)
    @name = name
    @description = description
    @parameters = parameters
    @properties = properties
    @example = example
    @changeable_properties = changeable_properties
  end
end

class Summary < Mustache
  self.template_path = './templates'
  self.template_file = './templates/summary.mustache'

  attr_accessor :types

  def initialize(types)
    @types = types || []
  end
end

def generate_type_doc(type)
  puppet_type = Puppet::Type.type(type).new({ name: 'sample' })

  doc = Puppet::Type.type(type).doc
  changeable_properties = Puppet::Type.type(type).instance_variable_get(:@changeable_properties) 

  parameters = Puppet::Type.type(type).parameters.map do
    |param|
    param_class = Puppet::Type.type(type).paramclass(param)
    { 
      name:param_class.name,
      doc: param_class.doc.gsub("\n", ' '),
      required: param_class.required?,
    }
  end

  properties = Puppet::Type.type(type).properties.map do
    |property|
    default_value = puppet_type.properties.find { |el| el.name == property.name }
    {
      name: property.name,
      doc: property.doc.gsub("\n", ' '),
      required: property.required? ? 'Yes' : 'No',
      default_value: default_value ? default_value.should : '-',
    }
  end

  example = nil
  begin
    example = File.open("../examples/#{type.to_s}.pp").read
  rescue Exception => e
    puts e
  end


  filename = "types/#{type.to_s}.md"

  File.open(filename, 'w') { |f|
    f.write(
      Type.new(
        type,
        doc,
        parameters,
        properties,
        example,
        changeable_properties,
      ).render,
    )
  }

  puts "Generated documentation for #{type}."
  return type, filename
end

all_types = []
Dir["../lib/puppet/type/*.rb"].each { |file| require file; all_types << file.split('/')[-1].split('.')[0] }

generated_types = []

all_types.each {
  |type|
  begin
    type_name, filename = generate_type_doc(type)
    generated_types.append({ title: type_name, filename: filename })
  rescue Exception => exc
    puts "Could not generate doc for #{type}. Error: #{exc}"
    # raise exc
  end
}

generated_types.sort! { |a, b| a[:title] <=> b[:title] }

File.open('summary.md', 'w') { |f|
  f.write(Summary.new(generated_types).render,)
}
