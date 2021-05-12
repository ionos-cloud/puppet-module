require 'spec_helper'

provider_class = Puppet::Type.type(:pcc).provider(:v1)

describe provider_class do
  context 'PCC operations' do
    before(:all) do
      @resource = Puppet::Type.type(:pcc).new(
        name: 'Puppet Module Test',
        description: 'Puppet Module Test description',
        peers: [
          {
            'name' => 'Puppet Module Test',
            'datacenter_name' => 'Puppet Module Test',
          }
        ]
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Pcc::ProviderV1
    end

    it 'should create Ionoscloud PCC' do
      VCR.use_cassette('pcc_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq('Puppet Module Test')
      end
    end

    it 'should list PCC instances' do
      VCR.use_cassette('pcc_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Pcc::ProviderV1
      end
    end

    it 'should update PCC' do
      VCR.use_cassette('pcc_update') do
        new_description = 'new_description'
        @provider.description = new_description
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'Puppet Module Test'
        end
        expect(updated_instance.description).to eq(new_description)
      end
    end

    it 'should update PCC peers' do
      VCR.use_cassette('pcc_update_peers') do
        peers = []
        my_instance = nil
        provider_class.instances.each do |instance|
          my_instance = instance if instance.name == 'Puppet Module Test'
        end

        expect(my_instance.peers.length).to eq(1)
        expect(my_instance.peers[0][:name]).to eq('Puppet Module Test')
        expect(my_instance.peers[0][:datacenter_name]).to eq('Puppet Module Test')

        my_instance.peers = peers
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'Puppet Module Test'
        end
        expect(updated_instance.peers).to eq([])
      end
    end

    it 'should delete PCC' do
      VCR.use_cassette('pcc_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
