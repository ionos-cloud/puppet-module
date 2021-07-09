require 'spec_helper'

require 'securerandom'

provider_class = Puppet::Type.type(:k8s_nodepool).provider(:v1)

describe provider_class do
  context 'k8s cluster operations' do
    before(:all) do
      VCR.use_cassette('k8s_nodepool_prepare') do
        @cluster_name = 'puppet_module_testa'
        @cluster_id = create_cluster(@cluster_name)

        @datacenter_name = 'puppet_module_tes24334gvg3v43vg4b390h30'
        create_datacenter(@datacenter_name)

        @lan_name = 'puppet_module_test62342423f43434qfbc5ed'
        @lan_id = create_private_lan(@datacenter_name, @lan_name)

        @nodepool_name = 'puppet_module_test6f23424f343434345wfbc5ed'

        @resource = Puppet::Type.type(:k8s_nodepool).new(
          name: @nodepool_name,
          cluster_name: @cluster_name,
          datacenter_name: @datacenter_name,
          k8s_version: '1.18.5',
          maintenance_day: 'Sunday',
          maintenance_time: '14:53:00Z',
          min_node_count: 1,
          max_node_count: 2,
          node_count: 1,
          cores_count: 1,
          cpu_family: 'INTEL_XEON',
          ram_size: 2048,
          storage_type: 'SSD',
          storage_size: 10,
          availability_zone: 'AUTO',
        )
        @provider = provider_class.new(@resource)
      end
    end

    after(:all) do
      VCR.use_cassette('k8s_nodepool_cleanup') do
        wait_cluster_active(@cluster_id)
        delete_cluster(@cluster_name)
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::K8s_nodepool::ProviderV1
    end

    it 'creates IonosCloud k8s nodepool with minimum params' do
      VCR.use_cassette('k8s_nodepool_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq(@nodepool_name)
        wait_nodepool_active(@cluster_id, @provider.id)
      end
    end

    it 'lists k8s nodepool instances' do
      VCR.use_cassette('k8s_nodepool_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::K8s_nodepool::ProviderV1
      end
    end

    it 'updates k8s nodepool' do
      VCR.use_cassette('k8s_nodepool_update') do
        new_version = '1.18.9'
        new_lans = [Integer(@lan_id)]
        my_instance = nil
        provider_class.instances.each do |nodepool|
          my_instance = nodepool if nodepool.name == @nodepool_name
        end
        my_instance.k8s_version = new_version
        my_instance.lans = new_lans
        my_instance.flush
        wait_nodepool_active(@cluster_id, @provider.id)
        updated_instance = nil
        provider_class.instances.each do |nodepool|
          updated_instance = nodepool if nodepool.name == @nodepool_name
        end
        expect(updated_instance.k8s_version).to eq(new_version)
        expect(updated_instance.lans).to eq(new_lans)
      end
    end

    it 'deletes k8s nodepool' do
      VCR.use_cassette('k8s_nodepool_delete') do
        sleep(100)
        wait_nodepool_active(@cluster_id, @provider.id)
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
