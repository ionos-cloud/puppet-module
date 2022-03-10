require 'spec_helper'

provider_class = Puppet::Type.type(:postgres_cluster).provider(:v1)

describe provider_class do
  context 'postgres_cluster operations' do
    before(:all) do
      VCR.use_cassette('postgres_cluster_prepare') do
        @datacenter_name = 'puppet_module_test04caw234t334g3h4332525d099c46550'
        @lan_name = 'puppet_module_test04cacdaf2f3f2c41bd099c46553'
        create_datacenter(@datacenter_name)
        create_private_lan(@datacenter_name, @lan_name)

        @postgres_cluster_name = 'puppet_module_test04cacqwfqfqf2f2f23f3246558'

        @resource = Puppet::Type.type(:postgres_cluster).new(
          display_name: @postgres_cluster_name,
          postgres_version: '12',
          instances: 1,
          cores_count: 1,
          ram_size: 2048,
          storage_size: 4096,
          storage_type: 'HDD',
          connections: [
            {
              'datacenter' => @datacenter_name,
              'lan' => @lan_name,
              'cidr' => '192.168.1.106/24',
            }
          ],
          location: 'de/txl',
          maintenance_day: 'Sunday',
          maintenance_time: '16:30:59',
          db_username: 'test',
          db_password: '7357cluster',
          synchronization_mode: 'ASYNCHRONOUS',
        )
        @provider = provider_class.new(@resource)
      end
    end

    after(:all) do
      VCR.use_cassette('postgres_cluster_cleanup') do
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Postgres_cluster::ProviderV1
      expect(@provider.name).to eq(@postgres_cluster_name)
    end

    it 'creates postgres_cluster' do
      VCR.use_cassette('postgres_cluster_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq(@postgres_cluster_name)
        wait_postgres_cluster_available(@provider.id)
      end
    end

    it 'lists postgres_cluster instances' do
      VCR.use_cassette('postgres_cluster_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Postgres_cluster::ProviderV1
      end
    end

    it 'updates postgres_cluster' do
      VCR.use_cassette('postgres_cluster_update') do
        new_storage_size = 8096
        @provider.storage_size = new_storage_size
        @provider.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @postgres_cluster_name
        end
        expect(updated_instance.storage_size).to eq(new_storage_size)
        wait_postgres_cluster_available(@provider.id)
      end
    end

    it 'restores postgres_cluster' do
      VCR.use_cassette('postgres_cluster_restore') do
        sleep(1000)
        backup = get_postgres_backup(@provider.id)
        @provider.backup_id = backup.id
        expect(@provider.restore = true).to be_truthy
        wait_postgres_cluster_available(@provider.id)
      end
    end

    it 'deletes postgres_cluster' do
      VCR.use_cassette('postgres_cluster_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
