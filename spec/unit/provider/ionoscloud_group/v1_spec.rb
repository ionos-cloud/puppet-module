require 'spec_helper'

provider_class = Puppet::Type.type(:ionoscloud_group).provider(:v1)

describe provider_class do
  context 'ionoscloud_group operations' do
    before(:all) do
      @group_name = 'puppet_module_test6f2c9f7a96c14ef08d20f796d0ebc5ed'
      @resource = Puppet::Type.type(:ionoscloud_group).new(
        name: @group_name,
        create_data_center: true,
        create_snapshot: true,
        reserve_ip: true,
        access_activity_log: true,
        s3_privilege: true,
        create_backup_unit: true,
        create_internet_access: true,
        create_k8s_cluster: true,
        create_pcc: true,
      )
      @provider = provider_class.new(@resource)
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Ionoscloud_group::ProviderV1
      expect(@provider.name).to eq(@group_name)
    end

    it 'creates ionoscloud_group' do
      VCR.use_cassette('ionoscloud_group_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq(@group_name)
      end
    end

    it 'lists ionoscloud_group instances' do
      VCR.use_cassette('ionoscloud_group_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Ionoscloud_group::ProviderV1
      end
    end

    it 'updates ionoscloud_group' do
      VCR.use_cassette('ionoscloud_group_update') do
        @provider.create_data_center = false
        @provider.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @group_name
        end
        expect(updated_instance.create_data_center).to eq(false)
      end
    end

    it 'deletes ionoscloud_group' do
      VCR.use_cassette('ionoscloud_group_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
