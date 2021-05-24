require 'spec_helper'

provider_class = Puppet::Type.type(:share).provider(:v1)

describe provider_class do
  context 'share operations' do
    before(:all) do
      VCR.use_cassette('share_prepare') do
        @datacenter_name = 'puppet_module_test6f2c9f7a96c14sfgddsgh5eh4d0ebc5ed'
        @group_name = 'puppet_module_test6f2c9f7a96c1sadadasah5eh4d0ebc5ed'
        @datacenter_id = create_datacenter(@datacenter_name)
        create_group(@group_name)

        @resource = Puppet::Type.type(:share).new(
          name: @datacenter_id,
          group_name: @group_name,
          edit_privilege: true,
          share_privilege: true,
        )
        @provider = provider_class.new(@resource)
      end
    end

    after(:all) do
      VCR.use_cassette('share_cleanup') do
        delete_group(@group_name)
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Share::ProviderV1
      expect(@provider.name).to eq(@datacenter_id)
    end

    it 'adds share' do
      VCR.use_cassette('share_add') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq(@datacenter_id)
      end
    end

    it 'lists share instances' do
      VCR.use_cassette('share_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Share::ProviderV1
      end
    end

    it 'updates share' do
      VCR.use_cassette('share_update') do
        @provider.edit_privilege = false
        @provider.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @datacenter_id
        end
        expect(updated_instance.edit_privilege).to eq(false)
      end
    end

    it 'removes share' do
      VCR.use_cassette('share_remove') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
