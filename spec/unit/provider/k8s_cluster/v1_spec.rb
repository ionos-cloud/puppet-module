require 'spec_helper'

provider_class = Puppet::Type.type(:k8s_cluster).provider(:v1)

describe provider_class do
  context 'k8s cluster operations' do
    before(:all) do
      @cluster_name = 'puppet_module_test6fqfwqfqfqwfddsgh5eh4d0ebc5ed'
      @resource = Puppet::Type.type(:k8s_cluster).new(
        name: @cluster_name,
        k8s_version: '1.18.5',
        maintenance_day: 'Sunday',
        maintenance_time: '14:53:00Z',
      )
      @provider = provider_class.new(@resource)
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::K8s_cluster::ProviderV1
    end

    it 'creates IonosCloud k8s cluster with minimum params' do
      VCR.use_cassette('k8s_cluster_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq(@cluster_name)
        wait_cluster_active(@provider.id)
      end
    end

    it 'lists k8s cluster instances' do
      VCR.use_cassette('k8s_cluster_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::K8s_cluster::ProviderV1
      end
    end

    it 'updates k8s cluster version' do
      VCR.use_cassette('k8s_cluster_update') do
        new_version = '1.18.9'
        my_instance = nil
        provider_class.instances.each do |cluster|
          my_instance = cluster if cluster.name == @cluster_name
        end
        my_instance.k8s_version = new_version
        my_instance.flush
        wait_cluster_active(my_instance.id)
        updated_instance = nil
        provider_class.instances.each do |cluster|
          updated_instance = cluster if cluster.name == @cluster_name
        end
        expect(updated_instance.k8s_version).to eq(new_version)
      end
    end

    it 'deletes k8s cluster' do
      VCR.use_cassette('k8s_cluster_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
        cluster = Ionoscloud::KubernetesApi.new.k8s_find_by_cluster_id(@provider.id)
        expect(cluster.metadata.state).to eq('DESTROYING')
      end
    end
  end
end
