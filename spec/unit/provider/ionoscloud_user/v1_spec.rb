require 'spec_helper'

provider_class = Puppet::Type.type(:ionoscloud_user).provider(:v1)

describe provider_class do
  context 'ionoscloud_user operations' do
    before(:all) do
      VCR.use_cassette('ionoscloud_user_prepare') do
        @email = "johnf2c9f7a96c14ef08d20f796d0ebc5ed@doe.com"
        @group_name = 'puppet_module_test6f2c9f7a96c14ef08d20f796d0ebc5ed'
        create_group(@group_name)

        @resource = Puppet::Type.type(:ionoscloud_user).new(
          firstname: 'John',
          lastname: 'Doe',
          email: @email,
          password: 'Secrete.Password.001',
          administrator: true,
        )
        @provider = provider_class.new(@resource)
      end
    end

    after(:all) do
      VCR.use_cassette('ionoscloud_user_cleanup') do
        delete_group(@group_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Ionoscloud_user::ProviderV1
      expect(@provider.name).to eq(@email)
    end

    it 'creates ionoscloud_user' do
      VCR.use_cassette('ionoscloud_user_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq(@email)
      end
    end

    it 'lists ionoscloud_user instances' do
      VCR.use_cassette('ionoscloud_user_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Ionoscloud_user::ProviderV1
      end
    end

    it 'updates ionoscloud_user' do
      VCR.use_cassette('ionoscloud_user_update') do
        @provider.administrator = false
        @provider.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.email == @email
        end
        expect(updated_instance.administrator).to eq(false)
      end
    end

    it 'adds ionoscloud_user to group' do
      VCR.use_cassette('ionoscloud_user_add_to_group') do
        @provider.groups = [@group_name]
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.email == @email
        end
        expect(updated_instance.groups).to eq([@group_name])
      end
    end

    it 'removes ionoscloud_user from group' do
      VCR.use_cassette('ionoscloud_user_remove_from_group') do
        @provider.groups = []
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.email == @email
        end
        expect(updated_instance.groups).to eq([])
      end
    end

    it 'deletes ionoscloud_user' do
      VCR.use_cassette('ionoscloud_user_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
