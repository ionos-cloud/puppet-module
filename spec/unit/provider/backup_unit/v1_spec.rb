require 'spec_helper'

provider_class = Puppet::Type.type(:backup_unit).provider(:v1)

describe provider_class do
  context 'backup unit operations' do
    before(:all) do
      @resource = Puppet::Type.type(:backup_unit).new(
        name: 'Puppet Module Test',
        email: 'email@email.email',
        password: 'securepassword123',
      )
      @provider = provider_class.new(@resource)
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Backup_unit::ProviderV1
    end

    it 'creates Ionoscloud backup unit with minimum params' do
      VCR.use_cassette('backupunit_create_min') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq('Puppet Module Test')
      end
    end

    it 'lists backup unit instances' do
      VCR.use_cassette('backupunit_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Backup_unit::ProviderV1
      end
    end

    it 'updates backup unit email' do
      VCR.use_cassette('backupunit_update') do
        new_email = 'new_email@email.email'
        @provider.email = new_email
        updated_instance = nil
        provider_class.instances.each do |backup_unit|
          updated_instance = backup_unit if backup_unit.name == 'Puppet Module Test'
        end
        expect(updated_instance.email).to eq(new_email)
      end
    end

    it 'deletes backup unit' do
      VCR.use_cassette('backupunit_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
