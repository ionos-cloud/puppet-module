require 'spec_helper'

provider_class = Puppet::Type.type(:share).provider(:v1)

describe provider_class do
  context 'share operations' do
    before(:all) do
      @resource = Puppet::Type.type(:share).new(
        name: 'bf8aa1ce-1176-4d57-b614-c6ee7c5ab27d',
        group_name: 'Puppet Module Test',
        edit_privilege: true,
        share_privilege: true
      )
      @provider = provider_class.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Share::ProviderV1
      expect(@provider.name).to eq('bf8aa1ce-1176-4d57-b614-c6ee7c5ab27d')
    end

    it 'should add share' do
      VCR.use_cassette('share_add') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq('bf8aa1ce-1176-4d57-b614-c6ee7c5ab27d')
      end
    end

    it 'should list share instances' do
      VCR.use_cassette('share_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Share::ProviderV1
      end
    end

    it 'should update share' do
      VCR.use_cassette('share_update') do
        @provider.edit_privilege = false
        @provider.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'bf8aa1ce-1176-4d57-b614-c6ee7c5ab27d'
        end
        expect(updated_instance.edit_privilege).to eq(false)
      end
    end

    it 'should remove share' do
      VCR.use_cassette('share_remove') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
