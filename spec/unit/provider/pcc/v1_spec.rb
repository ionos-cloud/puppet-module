require 'spec_helper'

provider_class = Puppet::Type.type(:pcc).provider(:v1)

describe provider_class do
  context 'PCC operations' do
    before(:all) do
      VCR.use_cassette('pcc_prepare') do
        @datacenter_name = 'puppet_module_test6f2nfctjrfqwfehh4d0ebc5ed'
        @lan_name = 'puppet_module_test6f2c9f7asdadfadddsgh5eh4d0ebc5ed'

        create_datacenter(@datacenter_name)
        create_private_lan(@datacenter_name, @lan_name)

        @pcc_name = 'puppet_module_teasdasdsada7a96c14sfgddsgh5eh4d0ebc5ed'

        @resource = Puppet::Type.type(:pcc).new(
          name: @pcc_name,
          description: 'Puppet Module Test description',
          peers: [
            {
              'name' => @lan_name,
              'datacenter_name' => @datacenter_name,
            },
          ],
        )
        @provider = provider_class.new(@resource)
      end
    end

    after(:all) do
      VCR.use_cassette('pcc_cleanup') do
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Pcc::ProviderV1
    end

    it 'creates Ionoscloud PCC' do
      VCR.use_cassette('pcc_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq(@pcc_name)
      end
    end

    it 'lists PCC instances' do
      VCR.use_cassette('pcc_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Pcc::ProviderV1
      end
    end

    it 'updates PCC' do
      VCR.use_cassette('pcc_update') do
        new_description = 'new_description'
        @provider.description = new_description
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @pcc_name
        end
        expect(updated_instance.description).to eq(new_description)
      end
    end

    it 'updates PCC peers' do
      VCR.use_cassette('pcc_update_peers') do
        peers = []
        my_instance = nil
        provider_class.instances.each do |instance|
          my_instance = instance if instance.name == @pcc_name
        end

        expect(my_instance.peers.length).to eq(1)
        expect(my_instance.peers[0][:name]).to eq(@lan_name)
        expect(my_instance.peers[0][:datacenter_name]).to eq(@datacenter_name)

        my_instance.peers = peers
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @pcc_name
        end
        expect(updated_instance.peers).to eq([])
      end
    end

    it 'deletes PCC' do
      VCR.use_cassette('pcc_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
