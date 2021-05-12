require 'spec_helper'

type_class = Puppet::Type.type(:k8s_nodepool)

describe type_class do
  let :params do
    [
      :name,
    ]
  end

  let :properties do
    [
      :id,
      :k8s_version,
      :maintenance_day,
      :maintenance_time,
      :datacenter_id,
      :datacenter_name,
      :cluster_id,
      :cluster_name,
      :node_count,
      :min_node_count,
      :max_node_count,
      :cpu_family,
      :cores_count,
      :ram_size,
      :availability_zone,
      :storage_type,
      :storage_size,
      :state,
      :k8s_nodes,
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
    type_class.new(name: 'sample', ensure: :present)
  end

  it 'supports :absent as a value to :ensure' do
    type_class.new(name: 'sample', ensure: :absent)
  end
end
