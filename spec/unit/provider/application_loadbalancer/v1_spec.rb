require 'spec_helper'

provider_class = Puppet::Type.type(:application_loadbalancer).provider(:v1)

describe provider_class do
  context 'application_loadbalancer operations' do
    before(:all) do
      VCR.use_cassette('application_loadbalancer_prepare') do
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

        @ipblock1_id = create_ipblock(@ipblock_name)
        Puppet::Type.type(:ipblock).provider(:v1).instances.each do |instance|
          @ipblock1 = instance if instance.id == @ipblock1_id
        end
        @ip1, @ip2 = *@ipblock1.ips

        @ipblock2_id = create_ipblock(@ipblock_name2)
        Puppet::Type.type(:ipblock).provider(:v1).instances.each do |instance|
          @ipblock2 = instance if instance.id == @ipblock2_id
        end
        @ip3, @ip4 = *@ipblock2.ips

        @application_loadbalancer1_name = 'puppet_module_test1'
        @application_loadbalancer2_name = 'puppet_module_test2'

        @resource1 = Puppet::Type.type(:application_loadbalancer).new(
          name: @application_loadbalancer1_name,
          ips: [@ip2],
          lb_private_ips: ['10.12.106.235/24', '10.12.106.232/24'],
          target_lan: @lan_id1,
          listener_lan: @lan_id2,
          rules: [
            {
              'name' => 'regula',
              'protocol' => 'HTTP',
              'listener_ip' => @ip2,
              'listener_port' => 47,
              'client_timeout' => 50_000,
              'server_certificates' => [
              ],
              'http_rules' => [
                {
                  'name' => 'nume1',
                  'type' => 'REDIRECT',
                  'drop_query' => true,
                  'location' => 'www.ionos.com',
                  'status_code' => 303,
                  'conditions' => [
                    {
                      'type' => 'HEADER',
                      'condition' => 'STARTS_WITH',
                      'negate' => true,
                      'key' => 'forward-at',
                      'value' => 'Friday',
                    },
                  ],
                },
                {
                  'name' => 'nume2',
                  'type' => 'STATIC',
                  'status_code' => 303,
                  'response_message' => 'Application Down',
                  'content_type' => 'text/html',
                  'conditions' => [
                    {
                      'type' => 'QUERY',
                      'condition' => 'STARTS_WITH',
                      'negate' => true,
                      'key' => 'forward-at',
                      'value' => 'Friday',
                    },
                  ],
                },
              ]
            },
            {
              'name' => 'regula2',
              'protocol' => 'HTTP',
              'listener_ip' => @ip2,
              'listener_port' => 28,
              'health_check' => {
                'client_timeout' => 35_000,
              },
              'server_certificates' => [
              ],
              'http_rules' => [
              ]
            },
          ],
          datacenter_name: @datacenter_name,
        )
        @provider1 = provider_class.new(@resource1)

        @resource2 = Puppet::Type.type(:application_loadbalancer).new(
          name: @application_loadbalancer2_name,
          ips: [@ip3, @ip4],
          lb_private_ips: ['10.12.106.205/24', '10.12.106.222/24'],
          target_lan: @lan_id1,
          listener_lan: @lan_id2,
          rules: [],
          datacenter_name: @datacenter_name,
        )
        @provider2 = provider_class.new(@resource2)
      end
    end

    after(:all) do
      VCR.use_cassette('application_loadbalancer_cleanup') do
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider1).to be_an_instance_of Puppet::Type::Application_loadbalancer::ProviderV1
      expect(@provider1.name).to eq(@application_loadbalancer1_name)
      expect(@provider2).to be_an_instance_of Puppet::Type::Application_loadbalancer::ProviderV1
      expect(@provider2.name).to eq(@application_loadbalancer2_name)
    end

    it 'creates IonosCloud application_loadbalancer with rules' do
      VCR.use_cassette('application_loadbalancer_create_1') do
        expect(@provider1.create).to be_truthy
        expect(@provider1.exists?).to be true
        expect(@provider1.name).to eq(@application_loadbalancer1_name)
      end
    end

    it 'creates IonosCloud application_loadbalancer' do
      VCR.use_cassette('application_loadbalancer_create_2') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
        expect(@provider2.name).to eq(@application_loadbalancer2_name)
      end
    end

    it 'lists application_loadbalancer instances' do
      VCR.use_cassette('application_loadbalancer_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Application_loadbalancer::ProviderV1
      end
    end

    it 'updates application_loadbalancer' do
      VCR.use_cassette('application_loadbalancer_update1') do
        @provider1.ips = [@ip1, @ip2]
        @provider1.lb_private_ips = ['10.12.106.235/24', '10.12.106.232/24', '10.12.106.215/24']
        @provider1.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @application_loadbalancer1_name
        end
        expect(updated_instance.ips).to eq([@ip1, @ip2])
        expect(updated_instance.lb_private_ips.sort).to eq(['10.12.106.235/24', '10.12.106.232/24', '10.12.106.215/24'].sort)
      end
    end

    it 'updates application_loadbalancer lans' do
      VCR.use_cassette('application_loadbalancer_update2') do
        @provider2.target_lan = @lan_id3
        @provider2.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @application_loadbalancer2_name
        end
        expect(updated_instance.target_lan).to eq(@lan_id3)
      end
    end

    it 'updates application_loadbalancer rule' do
      next
      VCR.use_cassette('application_loadbalancer_update4') do
        @provider1.rules = [
          {
            'name' => 'regula',
            'protocol' => 'HTTP',
            'listener_ip' => @ip2,
            'listener_port' => 49,
            'client_timeout' => 50_000,
            'server_certificates' => [
            ],
            'http_rules' => [
              {
                'name' => 'nume3',
                'type' => 'STATIC',
                'response_message' => 'Test message.',
                'status_code' => 303,
                'conditions' => [
                  {
                    'type' => 'PATH',
                    'condition' => 'STARTS_WITH',
                    'negate' => true,
                    'value' => 'Sunday',
                  },
                ],
              },
              {
                'name' => 'nume2',
                'type' => 'STATIC',
                'status_code' => 599,
                'response_message' => 'Application Still Down',
                'content_type' => 'application/json',
                'conditions' => [
                  {
                    'type' => 'HEADER',
                    'condition' => 'STARTS_WITH',
                    'negate' => true,
                    'key' => nil,
                    'value' => 'Friday',
                  },
                ],
              },
            ]
          },
          {
            'name' => 'regula2',
            'protocol' => 'HTTP',
            'listener_ip' => @ip1,
            'listener_port' => 23,
            'client_timeout' => 45_000,
            'server_certificates' => [
            ],
            'http_rules' => [
            ]
          },
        ]
        @provider1.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @application_loadbalancer1_name
        end

        expect(updated_instance.rules.first[:name]).to eq('regula')
        expect(updated_instance.rules.first[:protocol]).to eq('HTTP')
        expect(updated_instance.rules.first[:listener_ip]).to eq(@ip2)
        expect(updated_instance.rules.first[:listener_port]).to eq(49)
        expect(updated_instance.rules.first[:client_timeout]).to eq(50_000)
        expect(updated_instance.rules.first[:server_certificates]).to eq([])
        expect(updated_instance.rules.first[:http_rules].first[:name]).to eq('nume3')
        expect(updated_instance.rules.first[:http_rules].first[:type]).to eq('STATIC')
        expect(updated_instance.rules.first[:http_rules].first[:response_message]).to eq('Test message.')
        expect(updated_instance.rules.first[:http_rules].first[:status_code]).to eq(303)
        expect(updated_instance.rules.first[:http_rules].first[:conditions]).to eq([
                                                                                  {
                                                                                    type: 'PATH',
                                                                                    condition: 'STARTS_WITH',
                                                                                    negate: true,
                                                                                    key: nil,
                                                                                    value: 'Sunday',
                                                                                  },
                                                                                ])

        expect(updated_instance.rules[1][:name]).to eq('regula2')
        expect(updated_instance.rules[1][:protocol]).to eq('HTTP')
        expect(updated_instance.rules[1][:listener_ip]).to eq(@ip1)
        expect(updated_instance.rules[1][:listener_port]).to eq(23)
        expect(updated_instance.rules[1][:server_certificates]).to eq([])
        expect(updated_instance.rules[1][:client_timeout]).to eq(45_000)
        expect(updated_instance.rules[1][:http_rules]).to eq([])
      end
    end

    it 'updates application_loadbalancer add rule' do
      VCR.use_cassette('application_loadbalancer_update5') do
        @provider2.rules = [
          {
            'name' => 'regula5',
            'protocol' => 'HTTP',
            'listener_ip' => @ip3,
            'listener_port' => 36,
            'client_timeout' => 50_000,
            'server_certificates' => [
            ],
            'http_rules' => [
              {
                'name' => 'nume3',
                'type' => 'STATIC',
                'response_message' => 'Test message.',
                'status_code' => 303,
                'conditions' => [
                  {
                    'type' => 'PATH',
                    'condition' => 'STARTS_WITH',
                    'negate' => true,
                    'value' => 'Sunday',
                  },
                ],
              },
              {
                'name' => 'nume2',
                'type' => 'STATIC',
                'status_code' => 599,
                'response_message' => 'Application Still Down',
                'content_type' => 'application/json',
                'conditions' => [
                  {
                    'type' => 'HEADER',
                    'condition' => 'STARTS_WITH',
                    'negate' => true,
                    'key' => 'forward-at',
                    'value' => 'Friday',
                  },
                ],
              },
            ]
          },
        ]
        @provider2.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @application_loadbalancer2_name
        end

        expect(updated_instance.rules.first[:name]).to eq('regula5')
        expect(updated_instance.rules.first[:protocol]).to eq('HTTP')
        expect(updated_instance.rules.first[:listener_ip]).to eq(@ip3)
        expect(updated_instance.rules.first[:listener_port]).to eq(36)
        expect(updated_instance.rules.first[:client_timeout]).to eq(50_000)
        expect(updated_instance.rules.first[:server_certificates]).to eq([])
        expect(updated_instance.rules.first[:http_rules].first[:name]).to eq('nume3')
        expect(updated_instance.rules.first[:http_rules].first[:type]).to eq('STATIC')
        expect(updated_instance.rules.first[:http_rules].first[:response_message]).to eq('Test message.')
        expect(updated_instance.rules.first[:http_rules].first[:status_code]).to eq(303)
        expect(updated_instance.rules.first[:http_rules].first[:conditions]).to eq([
                                                                                     {
                                                                                       type: 'PATH',
                                                                                       condition: 'STARTS_WITH',
                                                                                       negate: true,
                                                                                       key: nil,
                                                                                       value: 'Sunday',
                                                                                     },
                                                                                   ])
      end
    end

    it 'deletes application_loadbalancer' do
      VCR.use_cassette('application_loadbalancer_delete') do
        expect(@provider1.destroy).to be_truthy
        expect(@provider1.exists?).to be false
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
      end
    end
  end
end
