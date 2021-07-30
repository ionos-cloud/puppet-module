require 'spec_helper'

provider_class = Puppet::Type.type(:natgateway).provider(:v1)

describe provider_class do
  context 'natgateway operations' do
    before(:all) do
      VCR.use_cassette('natgateway_prepare') do
        @datacenter_name = 'puppet_module_test2523525325f796d0ebc5ed'
        @ipblock_name = 'puppet_module_test6f2c9f7a52352532552396d0ebc5ed'
        @ipblock_name2 = 'puppet_module_test6f2c9f7wfewfwfewfw396d0ebc5ed'
        create_datacenter(@datacenter_name)
        @ip1, @ip2 = *Ionoscloud::IPBlocksApi.new.ipblocks_find_by_id(create_ipblock(@ipblock_name)).properties.ips
        @ip3, @ip4 = *Ionoscloud::IPBlocksApi.new.ipblocks_find_by_id(create_ipblock(@ipblock_name2)).properties.ips

        @natgateway1_name = 'puppet_module_test1'
        @natgateway2_name = 'puppet_module_test2'

        @resource1 = Puppet::Type.type(:natgateway).new(
          name: @natgateway1_name,
          public_ips: [@ip1],
          lans: [],
          flowlogs: [
            {
              'name' => 'test123123133',
              'action' => 'ALL',
              'bucket' => 'testtest234134124214',
              'direction' => 'EGRESS',
            },
          ],
          rules: [
            {
              'name' => 'test_rule',
              'protocol' => 'TCP',
              'source_subnet' => '192.168.0.1/32',
              'target_subnet' => '192.168.0.4/32',
              'public_ip' => @ip1,
              'target_port_range' => {
                'start' => 22,
                'end' => 27,
              }
            },
          ],
          datacenter_name: @datacenter_name,
        )
        @provider1 = provider_class.new(@resource1)

        @resource2 = Puppet::Type.type(:natgateway).new(
          name: @natgateway2_name,
          public_ips: [@ip2],
          lans: [],
          flowlogs: [],
          rules: [],
          datacenter_name: @datacenter_name,
        )
        @provider2 = provider_class.new(@resource2)
      end
    end

    after(:all) do
      VCR.use_cassette('natgateway_cleanup') do
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider1).to be_an_instance_of Puppet::Type::Natgateway::ProviderV1
      expect(@provider1.name).to eq(@natgateway1_name)
      expect(@provider2).to be_an_instance_of Puppet::Type::Natgateway::ProviderV1
      expect(@provider2.name).to eq(@natgateway2_name)
    end

    it 'creates IonosCloud natgateway with flowlog and rule' do
      VCR.use_cassette('natgateway_create_1') do
        expect(@provider1.create).to be_truthy
        expect(@provider1.exists?).to be true
        expect(@provider1.name).to eq(@natgateway1_name)
      end
    end

    it 'creates IonosCloud natgateway' do
      VCR.use_cassette('natgateway_create_2') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
        expect(@provider2.name).to eq(@natgateway2_name)
      end
    end

    it 'lists natgateway instances' do
      VCR.use_cassette('natgateway_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Natgateway::ProviderV1
      end
    end

    it 'updates natgateway public_ips' do
      VCR.use_cassette('natgateway_update1') do
        @provider1.public_ips = [@ip1, @ip3]
        @provider1.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @natgateway1_name
        end
        expect(updated_instance.public_ips).to eq([@ip1, @ip3])
      end
    end

    it 'updates natgateway public_ips 2' do
      VCR.use_cassette('natgateway_update2') do
        @provider2.public_ips = [@ip4]
        @provider2.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @natgateway2_name
        end
        expect(updated_instance.public_ips).to eq([@ip4])
      end
    end

    it 'updates natgateway flowlog' do
      VCR.use_cassette('natgateway_update3') do
        my_instance = nil
        provider_class.instances.each do |instance|
          my_instance = instance if instance.name == @natgateway1_name
        end
        my_instance.flowlogs = [
          {
            'name' => 'test123123133',
            'action' => 'ALL',
            'bucket' => 'testtest234134124214',
            'direction' => 'INGRESS',
          },
        ]
        my_instance.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @natgateway1_name
        end
        expect(updated_instance.flowlogs.first[:name]).to eq('test123123133')
        expect(updated_instance.flowlogs.first[:action]).to eq('ALL')
        expect(updated_instance.flowlogs.first[:bucket]).to eq('testtest234134124214')
        expect(updated_instance.flowlogs.first[:direction]).to eq('INGRESS')
      end
    end

    it 'updates natgateway add rule' do
      VCR.use_cassette('natgateway_update4') do
        @provider2.rules = [
          {
            'name' => 'test_rule',
            'protocol' => 'TCP',
            'source_subnet' => '192.168.0.1/32',
            'target_subnet' => '192.168.0.4/32',
            'public_ip' => @ip4,
            'target_port_range' => {
              'start' => 22,
              'end' => 27,
            }
          },
        ]
        @provider2.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @natgateway2_name
        end

        expect(updated_instance.rules.first[:name]).to eq('test_rule')
        expect(updated_instance.rules.first[:protocol]).to eq('TCP')
        expect(updated_instance.rules.first[:source_subnet]).to eq('192.168.0.1/32')
        expect(updated_instance.rules.first[:target_subnet]).to eq('192.168.0.4/32')
        expect(updated_instance.rules.first[:public_ip]).to eq(@ip4)
        expect(updated_instance.rules.first[:target_port_range][:start]).to eq(22)
        expect(updated_instance.rules.first[:target_port_range][:end]).to eq(27)
      end
    end

    it 'deletes natgateway' do
      VCR.use_cassette('natgateway_delete') do
        expect(@provider1.destroy).to be_truthy
        expect(@provider1.exists?).to be false
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
      end
    end
  end
end
