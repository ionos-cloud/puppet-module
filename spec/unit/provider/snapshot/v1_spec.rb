require 'spec_helper'

provider_class = Puppet::Type.type(:snapshot).provider(:v1)

describe provider_class do
  context 'snapshot operations' do
    before(:all) do
      VCR.use_cassette('snapshot_prepare') do
        @datacenter_name = 'puppet_module_test04cacda602e04de3b7c41bd099c46550'
        @volume_name = 'puppet_module_test04cacda602e04de3b7c41bd099c46553'
        create_datacenter(@datacenter_name)
        create_volume(@datacenter_name, @volume_name)

        @snapshot_name = 'puppet_module_test04cacda602e04de3b7c41bd099c46558'

        @resource = Puppet::Type.type(:snapshot).new(
          name: @snapshot_name,
          description: 'Puppet Module test snapshot',
          volume: @volume_name,
          datacenter: @datacenter_name,
        )
        @provider = provider_class.new(@resource)
      end
    end

    after(:all) do
      VCR.use_cassette('snapshot_cleanup') do
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Snapshot::ProviderV1
      expect(@provider.name).to eq(@snapshot_name)
    end

    it 'creates snapshot' do
      VCR.use_cassette('snapshot_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq(@snapshot_name)
      end
    end

    it 'lists snapshot instances' do
      VCR.use_cassette('snapshot_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Snapshot::ProviderV1
      end
    end

    it 'updates snapshot' do
      VCR.use_cassette('snapshot_update') do
        new_desc = 'Puppet Module test snapshot - RENAME'
        @provider.description = new_desc
        @provider.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @snapshot_name
        end
        expect(updated_instance.description).to eq(new_desc)
      end
    end

    it 'restores snapshot' do
      VCR.use_cassette('snapshot_restore') do
        expect(@provider.restore = true).to be_truthy
      end
    end

    it 'deletes snapshot' do
      VCR.use_cassette('snapshot_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
