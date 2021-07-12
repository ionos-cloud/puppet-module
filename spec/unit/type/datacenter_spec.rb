require 'spec_helper'

type_class = Puppet::Type.type(:datacenter)

describe type_class do
  let :params do
    [
      :name,
    ]
  end

  let :properties do
    [
      :ensure,
      :id,
      :description,
      :location,
      :sec_auth_protection,
      :version,
      :features,
      :cpu_architecture,
    ]
  end

  it 'has expected properties' do
    properties.each do |property|
      expect(type_class.properties.map(&:name)).to be_include(property)
    end
  end

  it 'has expected parameters' do
    params.each do |param|
      expect(type_class.parameters).to be_include(param)
    end
  end

  it 'requires a name' do
    expect {
      type_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'supports :present as a value to :ensure' do
    type_class.new(name: 'testdc', ensure: :present, location: 'dummy')
  end

  it 'supports :absent as a value to :ensure' do
    type_class.new(name: 'testdc', ensure: :absent)
  end
end
