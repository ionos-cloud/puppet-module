require 'spec_helper'

type_class = Puppet::Type.type(:postgres_cluster)

describe type_class do
  let :params do
    [
      :display_name,
    ]
  end

  let :properties do
    [
      :restore,
      :postgres_version,
      :maintenance_day,
      :maintenance_time,
      :instances,
      :cores_count,
      :ram_size,
      :storage_size,
      :storage_type,
      :location,
      :backup_location,
      :synchronization_mode,
      :connections,
      :id,
      :state,
      :backups,
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
    type_class.new(name: 'test', ensure: :present)
  end

  it 'supports :absent as a value to :ensure' do
    type_class.new(name: 'test', ensure: :absent)
  end
end
