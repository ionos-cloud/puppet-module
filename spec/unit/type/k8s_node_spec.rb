require 'spec_helper'

type_class = Puppet::Type.type(:k8s_node)

describe type_class do
  let :params do
    [
      :name
    ]
  end

  let :properties do
    [
      :k8s_version,
      :public_ip,
      :state,
      :nodepool_id,
      :nodepool_name,
      :cluster_id,
      :cluster_name,
    ]
  end

  it 'should have expected properties' do
    properties.each do |property|
      expect(type_class.properties.map(&:name)).to be_include(property)
    end
  end

  it 'should have expected parameters' do
    params.each do |param|
      expect(type_class.parameters).to be_include(param)
    end
  end

  it 'should require a name' do
    expect {
      type_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should support :present as a value to :ensure' do
    type_class.new(:name => 'sample', :ensure => :present)
  end

  it 'should support :absent as a value to :ensure' do
    type_class.new(:name => 'sample', :ensure => :absent)
  end
end
