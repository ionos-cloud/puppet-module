require 'spec_helper'

type_class = Puppet::Type.type(:ipblock)

describe type_class do
  let :params do
    [
      :name,
    ]
  end

  let :properties do
    [
      :ensure,
      :location,
      :id,
      :size,
      :created_by,
      :ips,
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
    type_class.new(name: 'test', location: 'us/las', size: 1, ensure: :present)
  end

  it 'supports :absent as a value to :ensure' do
    type_class.new(name: 'test', location: 'us/las', size: 1, ensure: :absent)
  end

  it 'requires a location' do
    expect {
      type_class.new(name: 'test', location: '', size: 1)
    }.to raise_error(Puppet::ResourceError, %r{IP block location must be set})
  end

  it 'requires a size' do
    expect {
      type_class.new(name: 'test', location: 'us/las', size: 0)
    }.to raise_error(Puppet::ResourceError, %r{The size of the IP block must be an integer greater than zero.})
  end
end
