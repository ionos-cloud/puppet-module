require 'spec_helper'

type_class = Puppet::Type.type(:server)

describe type_class do
  let :params do
    [
      :name,
    ]
  end

  let :properties do
    [
      :id,
      :ensure,
      :boot_volume,
      :datacenter_id,
      :datacenter_name,
      :cpu_family,
      :cores,
      :ram,
      :availability_zone,
      :licence_type,
      :cdroms,
      :volumes,
      :purge_volumes,
      :nics,
      :nat,
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

  it 'supports :running as a value to :ensure' do
    type_class.new(name: 'sample', ensure: :running)
  end

  it 'supports :stopped as a value to :ensure' do
    type_class.new(name: 'sample', ensure: :stopped)
  end

  it 'if volumes included must include a volume name' do
    expect {
      type_class.new({ name: 'sample', volumes: [
                       { 'size' => 1 },
                     ] })
    }.to raise_error(Puppet::Error, %r{Volume must include name})
  end

  it 'if volumes included must include a volume size' do
    expect {
      type_class.new({ name: 'sample', volumes: [
                       { 'name' => 'sample' },
                     ] })
    }.to raise_error(Puppet::Error, %r{Volume must include size})
  end

  it 'defaults purge_volumes to false' do
    server = type_class.new(name: 'sample')
    expect(server[:purge_volumes]).to eq(:false)
  end

  it 'if nics included must include a nic name' do
    expect {
      type_class.new({ name: 'sample', nics: [{
                       'dhcp' => true,
        'lan' => 'sample'
                     }] })
    }.to raise_error(Puppet::Error, %r{NIC must include name})
  end

  it 'if nics included must include dhcp' do
    expect {
      type_class.new({ name: 'sample', nics: [{
                       'name' => 'sample',
        'lan' => 'sample'
                     }] })
    }.to raise_error(Puppet::Error, %r{NIC must include dhcp})
  end

  it 'if nics included must include a nic lan name' do
    expect {
      type_class.new({ name: 'sample', nics: [{
                       'name' => 'sample',
        'dhcp' => true
                     }] })
    }.to raise_error(Puppet::Error, %r{NIC must include lan})
  end
end
