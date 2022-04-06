require 'spec_helper'

provider_class = Puppet::Type.type(:vm_autoscaling_group).provider(:v1)

describe provider_class do
  context 'VM Autoscaling group operations' do
    before(:all) do
      VCR.use_cassette('vm_autoscaling_group_prepare') do
        @datacenter_name = 'puppet_module_test6ffnfqwfqwfqfqwfd0ebc5ed'
        @datacenter_location = 'us/las'
        @lan_name = 'puppet_module_test6f2cfwefwefwefwf5eh4d0ebc5ed'

        create_datacenter(@datacenter_name, @datacenter_location)
        @lan_id = create_private_lan(@datacenter_name, @lan_name)

        @vm_autoscaling_group_name = 'test_vm_autoscaling_group'

        @resource = Puppet::Type.type(:vm_autoscaling_group).new(
          name: @vm_autoscaling_group_name,
          datacenter: @datacenter_name,
          max_replica_count: 3,
          min_replica_count: 1,
          target_replica_count: 2,
          location: @datacenter_location,
          policy: {
              'metric' => 'INSTANCE_CPU_UTILIZATION_AVERAGE',
              'range' => 'PT24H',
              'scale_in_action' => {
                  'amount' => 1,
                  'amount_type' => 'ABSOLUTE',
                  'cooldown_period' => 'PT5M',
                  'termination_policy' => 'RANDOM'
              },
              'scale_in_threshold' => 33,
              'scale_out_action' => {
                  'amount' => 2,
                  'amount_type' => 'ABSOLUTE',
                  'cooldown_period' => 'PT5M',
              },
              'scale_out_threshold' => 77,
              'unit' => 'PER_HOUR'
          },
          replica_configuration: {
              'availability_zone' => 'ZONE_1',
              'cores' => 2,
              'cpu_family' => 'INTEL_XEON',
              'ram' => 1024,
              'nics' => [
                  {
                      'lan' => Integer(@lan_id),
                      'name' => 'TEST_NIC1',
                      'dhcp' => true,
                  },
              ],
              'volumes' => [
                  {
                      'image' => 'cbc2fd40-6aae-11ec-a917-62772f9c5dc0',
                      'image_password' => 'test12345',
                      'name' => 'SDK_TEST_VOLUME',
                      'size' => 50,
                      'type' => 'HDD',
                      'bus' => 'IDE',
                  }
              ]
          },
        )
        @provider = provider_class.new(@resource)
      end
    end

    after(:all) do
      VCR.use_cassette('vm_autoscaling_group_cleanup') do
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Vm_autoscaling_group::ProviderV1
    end

    it 'creates IonosCloud VM Autoscaling group' do
      VCR.use_cassette('vm_autoscaling_group_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq(@vm_autoscaling_group_name)
      end
    end

    it 'lists VM Autoscaling group instances' do
      VCR.use_cassette('vm_autoscaling_group_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Vm_autoscaling_group::ProviderV1
      end
    end

    it 'updates VM Autoscaling group' do
      VCR.use_cassette('vm_autoscaling_group_update') do
        @provider.instance_variable_set(:@property_flush, {})
        @provider.max_replica_count = 4
        @provider.min_replica_count = 1
        @provider.target_replica_count = 2
        @provider.policy = {
          'metric' => 'INSTANCE_CPU_UTILIZATION_AVERAGE',
          'range' => 'PT24H',
          'scale_in_action' => {
              'amount' => 3,
              'amount_type' => 'ABSOLUTE',
              'cooldown_period' => 'PT5M',
              'termination_policy' => 'RANDOM'
          },
          'scale_in_threshold' => 33,
          'scale_out_action' => {
              'amount' => 2,
              'amount_type' => 'ABSOLUTE',
              'cooldown_period' => 'PT5M',
          },
          'scale_out_threshold' => 77,
          'unit' => 'PER_HOUR'
        }
        @provider.replica_configuration = {
          'availability_zone' => 'ZONE_2',
          'cores' => 2,
          'cpu_family' => 'INTEL_XEON',
          'ram' => 2048,
          'nics' => [
              {
                  'lan' => Integer(@lan_id),
                  'name' => 'TEST_NIC1',
                  'dhcp' => true,
              },
          ],
        }
        @provider.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @vm_autoscaling_group_name
        end
        expect(updated_instance.max_replica_count).to eq(4)
        expect(updated_instance.policy[:scale_in_action][:amount]).to eq(3)
        expect(updated_instance.replica_configuration[:availability_zone]).to eq('ZONE_2')
        expect(updated_instance.replica_configuration[:ram]).to eq(2048)
      end
    end

    it 'deletes VM Autoscaling group' do
      VCR.use_cassette('vm_autoscaling_group_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
