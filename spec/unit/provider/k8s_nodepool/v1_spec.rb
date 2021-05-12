require 'spec_helper'

provider_class = Puppet::Type.type(:k8s_nodepool).provider(:v1)

describe provider_class do
  context 'k8s cluster operations' do
    before(:all) do
      cluster_name = 'puppet_module_test'
      @resource = Puppet::Type.type(:k8s_nodepool).new(
        name: 'puppet_module_test',
        cluster_name: cluster_name,
        datacenter_name: 'Puppet Module Test',
        k8s_version: '1.18.5',
        maintenance_day: 'Sunday',
        maintenance_time: '14:53:00Z',
        min_node_count: 1,
        max_node_count: 2,
        node_count: 1,
        cores_count: 1,
        cpu_family: 'INTEL_SKYLAKE',
        ram_size: 2048,
        storage_type: 'SSD',
        storage_size: 10,
        availability_zone: 'AUTO',
      )
      @provider = provider_class.new(@resource)
      @cluster_id = '11542490-57e3-4995-9335-c84368b12b63'
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::K8s_nodepool::ProviderV1
    end

    it 'should create ProfitBricks k8s nodepool with minimum params' do
      VCR.use_cassette('k8s_nodepool_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq('puppet_module_test')
        wait_nodepool_active(@cluster_id, @provider.id)
      end
    end

    it 'should list k8s nodepool instances' do
      VCR.use_cassette('k8s_nodepool_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::K8s_nodepool::ProviderV1
      end
    end

    it 'should update k8s nodepool' do
      VCR.use_cassette('k8s_nodepool_update') do
        new_version = '1.18.9'
        new_node_count = 2
        my_instance = nil
        provider_class.instances.each do |nodepool|
          my_instance = nodepool if nodepool.name == 'puppet_module_test'
        end
        my_instance.k8s_version = new_version
        my_instance.node_count = new_node_count
        my_instance.flush
        wait_nodepool_active(@cluster_id, @provider.id)
        updated_instance = nil
        provider_class.instances.each do |nodepool|
          updated_instance = nodepool if nodepool.name == 'puppet_module_test'
        end
        expect(updated_instance.k8s_version).to eq(new_version)
        expect(updated_instance.node_count).to eq(new_node_count)
      end
    end

    it 'should update k8s nodepool 2' do
      VCR.use_cassette('k8s_nodepool_update2') do
        new_lans = [3]
        my_instance = nil
        provider_class.instances.each do |nodepool|
          my_instance = nodepool if nodepool.name == 'puppet_module_test'
        end
        my_instance.lans = new_lans
        my_instance.flush
        wait_nodepool_active(@cluster_id, @provider.id)
        updated_instance = nil
        provider_class.instances.each do |nodepool|
          updated_instance = nodepool if nodepool.name == 'puppet_module_test'
        end
        expect(updated_instance.lans).to eq(new_lans)
      end
    end

    it 'should delete k8s nodepool' do
      VCR.use_cassette('k8s_nodepool_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
        nodepool = Ionoscloud::KubernetesApi.new.k8s_nodepools_find_by_id(@cluster_id, @provider.id)
        expect(nodepool.metadata.state).to eq('DESTROYING')
      end
    end
  end
end
