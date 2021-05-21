require 'spec_helper'

provider_class = Puppet::Type.type(:lan).provider(:v1)

describe provider_class do
  context 'LAN operations' do
    before(:all) do
      VCR.use_cassette('lan_prepare') do
        @datacenter_name = 'puppet_module_test6f2c9fasdfwfgwegwedsgh5eh4d0ebc5ed'
        create_datacenter(@datacenter_name)
        
        @lan1_name = 'puppet_module_test6qfwqfqwfqwfqfwddsgh5eh4d0ebc5ed'
        @lan2_name = 'puppet_module_test6f2c9f7a9fqwfqfwqfqwh4d0ebc5ed'

        @resource1 = Puppet::Type.type(:lan).new(
          datacenter_name: @datacenter_name,
          name: @lan1_name,
        )
        @provider1 = provider_class.new(@resource1)

        @resource2 = Puppet::Type.type(:lan).new(
          datacenter_name: @datacenter_name,
          name: @lan2_name,
          public: true,
        )
        @provider2 = provider_class.new(@resource2)
      end
    end

    after(:all) do
      VCR.use_cassette('lan_cleanup') do
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider1).to be_an_instance_of Puppet::Type::Lan::ProviderV1
      expect(@provider2).to be_an_instance_of Puppet::Type::Lan::ProviderV1
    end

    it 'creates IonosCloud LAN with minimum params' do
      VCR.use_cassette('lan_create_min') do
        expect(@provider1.create).to be_truthy
        expect(@provider1.exists?).to be true
        expect(@provider1.name).to eq(@lan1_name)
      end
    end

    it 'creates IonosCloud LAN with all params' do
      VCR.use_cassette('lan_create_all') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
        expect(@provider2.name).to eq(@lan2_name)
      end
    end

    it 'lists LAN instances' do
      VCR.use_cassette('lan_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Lan::ProviderV1
      end
    end

    it 'updates public property of the LAN' do
      VCR.use_cassette('lan_update') do
        @provider2.public = false
        @provider2.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @lan2_name
        end
        expect(updated_instance.public).to eq(false)
      end
    end

    it 'deletes LAN' do
      VCR.use_cassette('lan_delete') do
        expect(@provider1.destroy).to be_truthy
        expect(@provider1.exists?).to be false
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
      end
    end
  end
end
