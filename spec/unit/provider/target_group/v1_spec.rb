require 'spec_helper'

provider_class = Puppet::Type.type(:target_group).provider(:v1)

describe provider_class do
  context 'target_group operations' do
    before(:all) do
      VCR.use_cassette('target_group_prepare') do
        @target_group1_name = 'puppet_module_test6f2nfctjrasfwefwgwgwdfqwfqwfq'
        @target_group2_name = 'puppet_module_test6f2nfctjrfqwfpmpamvpsjfewqfwqfqfwqd'

        @resource1 = Puppet::Type.type(:target_group).new(
          name: @target_group1_name,
          algorithm: 'LEAST_CONNECTION',
          protocol: 'HTTP',
          health_check: {
            'check_timeout' => 60,
            'check_interval' => 1000,
            'retries' => 3,
          },
          http_health_check: {
            'match_type' => 'STATUS_CODE',
            'response' => '200',
            'path' => '/.',
            'method' => 'GET',
          },
          targets: [
            {
              'ip' => '1.1.1.1',
              'weight' => 15,
              'port' => 20,
              'health_check_enabled' => true,
              'maintenance_enabled' => false,
            },
            {
              'ip' => '1.1.3.1',
              'weight' => 10,
              'port' => 22,
              'health_check_enabled' => false,
              'maintenance_enabled' => false,
            },
          ],
        )
        @provider1 = provider_class.new(@resource1)

        @resource2 = Puppet::Type.type(:target_group).new(
          name: @target_group2_name,
          algorithm: 'LEAST_CONNECTION',
          protocol: 'HTTP',
          health_check: {
            'check_timeout' => 53,
            'check_interval' => 1000,
            'retries' => 3,
          },
          http_health_check: {
            'match_type' => 'RESPONSE_BODY',
            'response' => '300',
            'path' => '/monitoring',
            'method' => 'TRACE',
          },
          targets: [
          ],
        )
        @provider2 = provider_class.new(@resource2)
      end
    end

    after(:all) do
      VCR.use_cassette('target_group_cleanup') do
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider1).to be_an_instance_of Puppet::Type::Target_group::ProviderV1
      expect(@provider1.name).to eq(@target_group1_name)
      expect(@provider2).to be_an_instance_of Puppet::Type::Target_group::ProviderV1
      expect(@provider2.name).to eq(@target_group2_name)
    end

    it 'creates IonosCloud target_group with rules' do
      VCR.use_cassette('target_group_create_1') do
        expect(@provider1.create).to be_truthy
        expect(@provider1.exists?).to be true
        expect(@provider1.name).to eq(@target_group1_name)
      end
    end

    it 'creates IonosCloud target_group' do
      VCR.use_cassette('target_group_create_2') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
        expect(@provider2.name).to eq(@target_group2_name)
      end
    end

    it 'lists target_group instances' do
      VCR.use_cassette('target_group_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Target_group::ProviderV1
      end
    end

    it 'updates target_group' do
      VCR.use_cassette('target_group_update1') do
        @provider1.algorithm = 'SOURCE_IP'
        @provider1.health_check = {
          'check_timeout' => 57,
          'retries' => 4,
        }
        @provider1.http_health_check = {
          'match_type' => 'STATUS_CODE',
          'response' => '304',
          'method' => 'POST',
        }
        @provider1.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @target_group1_name
        end
        expect(updated_instance.algorithm).to eq('SOURCE_IP')
        expect(updated_instance.health_check).to eq({
                                                      check_timeout: 57,
          check_interval: 1000,
          retries: 4,
                                                    })
        expect(updated_instance.http_health_check).to eq({
                                                           match_type: 'STATUS_CODE',
          method: 'POST',
          negate: false,
          path: '/.',
          regex: false,
          response: '304',
                                                         })
      end
    end

    it 'updates target_group targets' do
      VCR.use_cassette('target_group_update4') do
        @provider1.targets = [
          {
            'ip' => '1.1.1.1',
            'weight' => 20,
            'port' => 20,
            'health_check_enabled' => true,
            'maintenance_enabled' => false,
          },
          {
            'ip' => '1.1.3.1',
            'weight' => 23,
            'port' => 28,
            'health_check_enabled' => false,
            'maintenance_enabled' => false,
          },
        ]
        @provider1.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @target_group1_name
        end

        expect(updated_instance.targets).to eq([
                                                 {
                                                   health_check_enabled: true,
                                                   maintenance_enabled: false,
                                                   ip: '1.1.1.1',
                                                   port: 20,
                                                   weight: 20,
                                                 },
                                                 {
                                                   health_check_enabled: false,
                                                   maintenance_enabled: false,
                                                   ip: '1.1.3.1',
                                                   port: 28,
                                                   weight: 23,
                                                 },
                                               ])
      end
    end

    it 'updates target_group add target' do
      VCR.use_cassette('target_group_update5') do
        @provider2.targets = [
          {
            'ip' => '1.1.1.3',
            'weight' => 21,
            'port' => 21,
            'health_check_enabled' => false,
            'maintenance_enabled' => false,
          },
        ]
        @provider2.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @target_group2_name
        end

        expect(updated_instance.targets).to eq([
                                                 {
                                                   health_check_enabled: false,
                                                   maintenance_enabled: false,
                                                   ip: '1.1.1.3',
                                                   port: 21,
                                                   weight: 21,
                                                 },
                                               ])
      end
    end

    it 'deletes target_group' do
      VCR.use_cassette('target_group_delete') do
        expect(@provider1.destroy).to be_truthy
        expect(@provider1.exists?).to be false
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
      end
    end
  end
end
