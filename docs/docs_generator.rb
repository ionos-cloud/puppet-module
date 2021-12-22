#!/usr/bin/env ruby

# This must be run from /docs directory

require 'mustache'
require 'puppet'

$LOAD_PATH << '.'

# Mustache class for Puppet type documentation file
class Type < Mustache
  self.template_path = './templates'
  self.template_file = './templates/type_doc.mustache'

  attr_accessor :description, :name, :parameters, :properties, :example, :changeable_properties

  def initialize(name, description, parameters, properties, example, changeable_properties)
    super()
    @name = name
    @description = description
    @parameters = parameters
    @properties = properties
    @example = example
    @changeable_properties = changeable_properties
  end
end

# Mustache class for GitBook summary file
class Summary < Mustache
  self.template_path = './templates'
  self.template_file = './templates/summary.mustache'

  attr_accessor :types

  def initialize(types)
    super()
    @types = types || []
  end
end

def generate_type_doc(type)
  doc = Puppet::Type.type(type).doc
  changeable_properties = Puppet::Type.type(type).instance_variable_get(:@changeable_properties)

  parameters = Puppet::Type.type(type).parameters.map do |param|
    param_class = Puppet::Type.type(type).paramclass(param)
    {
      name: param_class.name,
      doc: param_class.doc.tr("\n", ' '),
      required: param_class.required?,
    }
  end

  properties = Puppet::Type.type(type).properties.map do |property|
    {
      name: property.name,
      doc: property.doc.tr("\n", ' '),
      required: property.required? ? 'Yes' : 'No',
    }
  end

  example = false
  begin
    example = File.open("../examples/#{type}.pp").read
  rescue Errno::ENOENT
    puts "No example found for #{type}, still generating."
  end

  filename = "types/#{type}.md"

  File.open(filename, 'w') do |f|
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
  end

  puts "Generated documentation for #{type}."
  [type, filename]
end

all_types = []
Dir['../lib/puppet/type/*.rb'].each do |file|
  require file
  all_types << file.split('/')[-1].split('.')[0]
end

generated_types = []

all_types.each do |type|
  begin
    type_name, filename = generate_type_doc(type)
    generated_types.append({ title: type_name, filename: filename })
  rescue StandardError => exc
    puts "Could not generate doc for #{type}. Error: #{exc}"
  end
end

generated_types.sort! { |a, b| a[:title] <=> b[:title] }

File.open('summary.md', 'w') do |f|
  f.write(Summary.new(generated_types).render)
end
