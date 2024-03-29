require 'spec_helper'

type_class = Puppet::Type.type(:location)

describe type_class do
  let :params do
    [
      :name,
    ]
  end

  let :properties do
    [
      :features,
      :image_aliases,
      :id,
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
end
