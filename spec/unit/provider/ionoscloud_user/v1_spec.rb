require 'spec_helper'

provider_class = Puppet::Type.type(:ionoscloud_user).provider(:v1)

describe provider_class do
  context 'ionoscloud_user operations' do
    before(:all) do
      @resource = Puppet::Type.type(:ionoscloud_user).new(
        firstname: 'John',
        lastname: 'Doe',
        email: 'john.doe_008@example.com',
        password: 'Secrete.Password.001',
        administrator: true
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Ionoscloud_user::ProviderV1
      expect(@provider.name).to eq('john.doe_008@example.com')
    end

    it 'should create ionoscloud_user' do
      VCR.use_cassette('ionoscloud_user_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq('john.doe_008@example.com')
      end
    end

    it 'should list ionoscloud_user instances' do
      VCR.use_cassette('ionoscloud_user_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Ionoscloud_user::ProviderV1
      end
    end

    it 'should update ionoscloud_user' do
      VCR.use_cassette('ionoscloud_user_update') do
        @provider.administrator = false
        @provider.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.email == 'john.doe_008@example.com'
        end
        expect(updated_instance.administrator).to eq(false)
      end
    end

    it 'should add ionoscloud_user to group' do
      VCR.use_cassette('ionoscloud_user_add_to_group') do
        @provider.groups = ['Puppet Module Test']
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.email == 'john.doe_008@example.com'
        end
        expect(updated_instance.groups).to eq(['Puppet Module Test'])
      end
    end

    it 'should remove ionoscloud_user from group' do
      VCR.use_cassette('ionoscloud_user_remove_from_group') do
        @provider.groups = []
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.email == 'john.doe_008@example.com'
        end
        expect(updated_instance.groups).to eq([])
      end
    end

    it 'should delete ionoscloud_user' do
      VCR.use_cassette('ionoscloud_user_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
