#!/usr/bin/env ruby

# This must be run from /docs directory

require 'mustache'
require 'fileutils'
require 'puppet'

$LOAD_PATH << '.'

FOLDER_TO_NAME_MAP = {
  'backup' => 'Managed Backup',
  'user' => 'User Management',
  'compute-engine' => 'Compute Engine',
  'kubernetes' => 'Managed Kubernetes',
  'dbaas-postgres' => 'DbaaS Postgres',
}.freeze

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

  attr_accessor :categories

  def initialize(categories)
    super()
    @categories = categories || []
  end
end

def generate_type_doc(type)
  doc = Puppet::Type.type(type).doc
  changeable_properties = Puppet::Type.type(type).instance_variable_get(:@changeable_properties)
  doc_directory = Puppet::Type.type(type).instance_variable_get(:@doc_directory)

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

  begin
    filename = "types/#{Puppet::Type.type(type).instance_variable_get(:@doc_directory)}/#{type}.md"
    category = FOLDER_TO_NAME_MAP[Puppet::Type.type(type).instance_variable_get(:@doc_directory)]
  rescue NoMethodError
    filename = "types/#{type}.md"
    category = ''
  end

  FileUtils.mkdir_p(File.dirname(filename)) unless File.directory?(File.dirname(filename))

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
  {
    title: type,
    filename: filename,
    category: category,
  }
end

all_types = []
Dir['../lib/puppet/type/*.rb'].each do |file|
  require file
  all_types << file.split('/')[-1].split('.')[0]
end

generated_types = []

all_types.each do |type|
  begin
    generated_types.append(generate_type_doc(type))
  rescue StandardError => exc
    puts "Could not generate doc for #{type}. Error: #{exc}"
  end
end

categories = {}

generated_types.map do |generated_type|
  if categories.key?(generated_type[:category])
    categories[generated_type[:category]] << generated_type
  else
    categories[generated_type[:category]] = [generated_type]
  end
end

final_categories = []

categories.map { |key, value| final_categories << { category: key, generated_types: value.sort { |a, b| a[:title] <=> b[:title] } } }

File.open('summary.md', 'w') { |f|
  f.write(Summary.new(final_categories).render)
}
