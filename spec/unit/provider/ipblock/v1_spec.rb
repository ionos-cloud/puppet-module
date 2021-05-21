require 'spec_helper'

provider_class = Puppet::Type.type(:ipblock).provider(:v1)

describe provider_class do
  context 'ipblock operations' do
    before(:all) do
      @ipblock_name = 'puppet_module_test6f2c9fewfewfgddqdqwdqw4d0ebc5ed'
      @resource = Puppet::Type.type(:ipblock).new(
        name: @ipblock_name,
        size: 2,
        location: 'us/las',
      )
      @provider = provider_class.new(@resource)
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Ipblock::ProviderV1
      expect(@provider.name).to eq(@ipblock_name)
    end

    it 'creates ipblock' do
      VCR.use_cassette('ipblock_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq(@ipblock_name)
      end
    end

    it 'lists ipblock instances' do
      VCR.use_cassette('ipblock_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Ipblock::ProviderV1
      end
    end

    it 'deletes ipblock' do
      VCR.use_cassette('ipblock_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
