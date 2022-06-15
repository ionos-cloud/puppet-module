require 'spec_helper'

provider_class = Puppet::Type.type(:networkloadbalancer).provider(:v1)

describe provider_class do
  context 'networkloadbalancer operations' do
    before(:all) do
      VCR.use_cassette('networkloadbalancer_prepare') do
        @datacenter_name = 'puppet_module_test2523525325f796d0ebc5ed'
        @lan_name1 = 'puppet_module_test2523525325f796d0ebc5edasdadwfwd'
        @lan_name2 = 'puppet_module_test2523525wegwgwegwc5edasdadwfwd'
        @lan_name3 = 'puppet_module_test2523525gwddbbndndtndasdadwfwd'
        @ipblock_name = 'puppet_module_test6f2c9f7a52352532552396d0ebc5ed'
        @ipblock_name2 = 'puppet_module_test6f2c9f7wfewfwfewfw396d0ebc5ed'
        create_datacenter(@datacenter_name)
        @lan_id1 = Integer(create_private_lan(@datacenter_name, @lan_name1))
        @lan_id2 = Integer(create_public_lan(@datacenter_name, @lan_name2))
        @lan_id3 = Integer(create_private_lan(@datacenter_name, @lan_name3))

        @ip1, @ip2 = *create_ipblock(@ipblock_name).ips
        @ip3, @ip4 = *create_ipblock(@ipblock_name2).ips

        @networkloadbalancer1_name = 'puppet_module_test1'
        @networkloadbalancer2_name = 'puppet_module_test2'

        @resource1 = Puppet::Type.type(:networkloadbalancer).new(
          name: @networkloadbalancer1_name,
          ips: [@ip1, @ip2],
          lb_private_ips: ['10.12.106.235/24', '10.12.106.232/24'],
          target_lan: @lan_id1,
          listener_lan: @lan_id2,
          flowlogs: [
            {
              'name' => 'test123123133',
              'action' => 'ALL',
              'bucket' => 'testtest234134124214',
              'direction' => 'INGRESS',
            },
          ],
          rules: [
            {
              'name' => 'regula',
              'algorithm' => 'ROUND_ROBIN',
              'protocol' => 'TCP',
              'listener_ip' => @ip1,
              'listener_port' => 22,
              'health_check' => {
                'client_timeout' => 40_000,
                'connect_timeout' => 3001,
                'target_timeout' => 20_000,
                'retries' => 4
              },
              'targets' => [
                'ip' => '1.1.1.1',
                'port' => 22,
                'weight' => 1,
                'health_check' => {
                  'check' => true,
                  'check_interval' => 2000,
                  'maintenance' => false,
                },
              ],
            },
          ],
          datacenter_name: @datacenter_name,
        )
        @provider1 = provider_class.new(@resource1)

        @resource2 = Puppet::Type.type(:networkloadbalancer).new(
          name: @networkloadbalancer2_name,
          ips: [@ip3, @ip4],
          lb_private_ips: ['10.12.106.225/24', '10.12.106.222/24'],
          target_lan: @lan_id1,
          listener_lan: @lan_id2,
          flowlogs: [],
          rules: [],
          datacenter_name: @datacenter_name,
        )
        @provider2 = provider_class.new(@resource2)
      end
    end

    after(:all) do
      VCR.use_cassette('networkloadbalancer_cleanup') do
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider1).to be_an_instance_of Puppet::Type::Networkloadbalancer::ProviderV1
      expect(@provider1.name).to eq(@networkloadbalancer1_name)
      expect(@provider2).to be_an_instance_of Puppet::Type::Networkloadbalancer::ProviderV1
      expect(@provider2.name).to eq(@networkloadbalancer2_name)
    end

    it 'creates IonosCloud networkloadbalancer with flowlog and rule' do
      VCR.use_cassette('networkloadbalancer_create_1') do
        expect(@provider1.create).to be_truthy
        expect(@provider1.exists?).to be true
        expect(@provider1.name).to eq(@networkloadbalancer1_name)
      end
    end

    it 'creates IonosCloud networkloadbalancer' do
      VCR.use_cassette('networkloadbalancer_create_2') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
        expect(@provider2.name).to eq(@networkloadbalancer2_name)
      end
    end

    it 'lists networkloadbalancer instances' do
      VCR.use_cassette('networkloadbalancer_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Networkloadbalancer::ProviderV1
      end
    end

    it 'updates networkloadbalancer' do
      VCR.use_cassette('networkloadbalancer_update1') do
        @provider1.ips = [@ip1]
        @provider1.lb_private_ips = ['10.12.106.235/24', '10.12.106.232/24', '10.12.106.215/24']
        @provider1.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @networkloadbalancer1_name
        end
        expect(updated_instance.ips).to eq([@ip1])
        expect(updated_instance.lb_private_ips.sort).to eq(['10.12.106.235/24', '10.12.106.232/24', '10.12.106.215/24'].sort)
      end
    end

    it 'updates networkloadbalancer lans' do
      VCR.use_cassette('networkloadbalancer_update2') do
        @provider2.target_lan = @lan_id3
        @provider2.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @networkloadbalancer2_name
        end
        expect(updated_instance.target_lan).to eq(@lan_id3)
      end
    end

    it 'updates networkloadbalancer flowlog' do
      VCR.use_cassette('networkloadbalancer_update3') do
        my_instance = nil
        provider_class.instances.each do |instance|
          my_instance = instance if instance.name == @networkloadbalancer1_name
        end
        my_instance.flowlogs = [
          {
            'name' => 'test123123133',
            'action' => 'ACCEPTED',
            'bucket' => 'testtest234134124214',
            'direction' => 'EGRESS',
          },
        ]
        my_instance.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @networkloadbalancer1_name
        end
        expect(updated_instance.flowlogs.first[:name]).to eq('test123123133')
        expect(updated_instance.flowlogs.first[:action]).to eq('ACCEPTED')
        expect(updated_instance.flowlogs.first[:bucket]).to eq('testtest234134124214')
        expect(updated_instance.flowlogs.first[:direction]).to eq('EGRESS')
      end
    end

    it 'updates networkloadbalancer rule' do
      VCR.use_cassette('networkloadbalancer_update4') do
        @provider1.rules = [
          {
            'name' => 'regula',
            'algorithm' => 'ROUND_ROBIN',
            'protocol' => 'TCP',
            'listener_ip' => @ip1,
            'listener_port' => 25,
            'health_check' => {
              'client_timeout' => 40_000,
              'connect_timeout' => 5001,
              'target_timeout' => 50_000,
              'retries' => 3
            },
            'targets' => [
              'ip' => '1.1.1.2',
              'port' => 22,
              'weight' => 1,
              'health_check' => {
                'check' => false,
                'check_interval' => 4000,
                'maintenance' => true,
              },
            ],
          },
        ]
        @provider1.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @networkloadbalancer1_name
        end

        expect(updated_instance.rules.first[:name]).to eq('regula')
        expect(updated_instance.rules.first[:algorithm]).to eq('ROUND_ROBIN')
        expect(updated_instance.rules.first[:protocol]).to eq('TCP')
        expect(updated_instance.rules.first[:listener_ip]).to eq(@ip1)
        expect(updated_instance.rules.first[:listener_port]).to eq(25)
        expect(updated_instance.rules.first[:health_check][:client_timeout]).to eq(40_000)
        expect(updated_instance.rules.first[:health_check][:connect_timeout]).to eq(5001)
        expect(updated_instance.rules.first[:health_check][:target_timeout]).to eq(50_000)
        expect(updated_instance.rules.first[:health_check][:retries]).to eq(3)
        expect(updated_instance.rules.first[:targets].first[:ip]).to eq('1.1.1.2')
        expect(updated_instance.rules.first[:targets].first[:port]).to eq(22)
        expect(updated_instance.rules.first[:targets].first[:weight]).to eq(1)
        expect(updated_instance.rules.first[:targets].first[:health_check][:check]).to eq(false)
        expect(updated_instance.rules.first[:targets].first[:health_check][:check_interval]).to eq(4000)
        expect(updated_instance.rules.first[:targets].first[:health_check][:maintenance]).to eq(true)
      end
    end

    it 'updates networkloadbalancer add rule' do
      VCR.use_cassette('networkloadbalancer_update5') do
        @provider2.rules = [
          {
            'name' => 'regula',
            'algorithm' => 'ROUND_ROBIN',
            'protocol' => 'TCP',
            'listener_ip' => @ip3,
            'listener_port' => 22,
            'health_check' => {
              'client_timeout' => 40_000,
              'connect_timeout' => 3001,
              'target_timeout' => 20_000,
              'retries' => 4
            },
            'targets' => [
              'ip' => '1.1.1.1',
              'port' => 22,
              'weight' => 1,
              'health_check' => {
                'check' => true,
                'check_interval' => 2000,
                'maintenance' => false,
              },
            ],
          },
        ]
        @provider2.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @networkloadbalancer2_name
        end

        expect(updated_instance.rules.first[:name]).to eq('regula')
        expect(updated_instance.rules.first[:algorithm]).to eq('ROUND_ROBIN')
        expect(updated_instance.rules.first[:protocol]).to eq('TCP')
        expect(updated_instance.rules.first[:listener_ip]).to eq(@ip3)
        expect(updated_instance.rules.first[:listener_port]).to eq(22)
        expect(updated_instance.rules.first[:health_check][:client_timeout]).to eq(40_000)
        expect(updated_instance.rules.first[:health_check][:connect_timeout]).to eq(3001)
        expect(updated_instance.rules.first[:health_check][:target_timeout]).to eq(20_000)
        expect(updated_instance.rules.first[:health_check][:retries]).to eq(4)
        expect(updated_instance.rules.first[:targets].first[:ip]).to eq('1.1.1.1')
        expect(updated_instance.rules.first[:targets].first[:port]).to eq(22)
        expect(updated_instance.rules.first[:targets].first[:weight]).to eq(1)
        expect(updated_instance.rules.first[:targets].first[:health_check][:check]).to eq(true)
        expect(updated_instance.rules.first[:targets].first[:health_check][:check_interval]).to eq(2000)
        expect(updated_instance.rules.first[:targets].first[:health_check][:maintenance]).to eq(false)
      end
    end

    it 'deletes networkloadbalancer' do
      VCR.use_cassette('networkloadbalancer_delete') do
        expect(@provider1.destroy).to be_truthy
        expect(@provider1.exists?).to be false
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
      end
    end
  end
end
