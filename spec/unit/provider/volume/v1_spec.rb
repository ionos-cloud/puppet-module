require 'spec_helper'

provider_class = Puppet::Type.type(:volume).provider(:v1)

describe provider_class do
  context 'volume operations' do
    before(:all) do
      VCR.use_cassette('volume_prepare') do
        @datacenter_name = 'puppet_module_test6f2c9f7a9r21t22g23g0f796d0ebc5ed'
        create_datacenter(@datacenter_name)

        @volume1_name = 'puppet_module_test1'
        @volume2_name = 'puppet_module_test2'

        @resource1 = Puppet::Type.type(:volume).new(
          name: @volume1_name,
          size: 3,
          licence_type: 'LINUX',
          availability_zone: 'ZONE_3',
          datacenter_name: @datacenter_name,
        )
        @provider1 = provider_class.new(@resource1)

        @resource2 = Puppet::Type.type(:volume).new(
          name: @volume2_name,
          size: 100,
          licence_type: 'LINUX',
          volume_type: 'SSD',
          availability_zone: 'AUTO',
          datacenter_name: @datacenter_name,
        )
        @provider2 = provider_class.new(@resource2)
      end
    end

    after(:all) do
      VCR.use_cassette('volume_cleanup') do
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider1).to be_an_instance_of Puppet::Type::Volume::ProviderV1
      expect(@provider1.name).to eq(@volume1_name)
      expect(@provider2).to be_an_instance_of Puppet::Type::Volume::ProviderV1
    end

    it 'creates IonosCloud HDD volume' do
      VCR.use_cassette('volume_create_hdd') do
        expect(@provider1.create).to be_truthy
        expect(@provider1.exists?).to be true
        expect(@provider1.name).to eq(@volume1_name)
      end
    end

    it 'creates IonosCloud SSD volume' do
      VCR.use_cassette('volume_create_ssd') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
        expect(@provider2.name).to eq(@volume2_name)
      end
    end

    it 'lists volume instances' do
      VCR.use_cassette('volume_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Volume::ProviderV1
      end
    end

    it 'updates volume size' do
      VCR.use_cassette('volume_update') do
        @provider1.size = 5
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @volume1_name
        end
        expect(updated_instance.size).to eq(5)
      end
    end

    it 'deletes volume' do
      VCR.use_cassette('volume_delete') do
        expect(@provider1.destroy).to be_truthy
        expect(@provider1.exists?).to be false
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
      end
    end
  end
end
