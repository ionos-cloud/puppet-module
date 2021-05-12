require 'spec_helper'

type_class = Puppet::Type.type(:snapshot)

describe type_class do
  let :params do
    [
      :name,
    ]
  end

  let :properties do
    [
      :ensure,
      :description,
      :datacenter,
      :volume,
      :location,
      :id,
      :size,
      :restore,
      :cpu_hot_plug,
      :cpu_hot_unplug,
      :ram_hot_plug,
      :ram_hot_unplug,
      :nic_hot_plug,
      :nic_hot_unplug,
      :disc_virtio_hot_plug,
      :disc_virtio_hot_unplug,
      :disc_scsi_hot_plug,
      :disc_scsi_hot_unplug,
      :licence_type,
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

  it 'requires a datacenter' do
    expect {
      type_class.new(name: 'test', datacenter: true)
    }.to raise_error(Puppet::ResourceError, %r{The data center ID/name should be a String.})
  end

  it 'requires a volume' do
    expect {
      type_class.new(name: 'test', volume: true)
    }.to raise_error(Puppet::ResourceError, %r{The volume ID/name should be a String.})
  end
end
