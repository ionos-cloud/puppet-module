require 'spec_helper'

provider_class = Puppet::Type.type(:firewall_rule).provider(:v1)

describe provider_class do
  context 'firewall rule operations' do
    before(:all) do
      VCR.use_cassette('firewall_rule_prepare') do
        @datacenter_name = 'puppet_module_testubnfctjrfqwfeh4d0ebc5ed'
        @server_name = 'puppet_module_test6fqfwqfqfwqfh4d0ebc5ed'
        @lan_name = 'puppet_module_test6fqfwqfqfqfqwfwqh4d0ebc5ed'
        @nic_name = 'puppet_module_test6fqfwqffqwfwqfqeh4d0ebc5ed'

        create_datacenter(@datacenter_name)
        create_server(@datacenter_name, @server_name)
        create_private_lan(@datacenter_name, @lan_name)
        create_nic(@datacenter_name, @server_name, @lan_name, @nic_name)

        @resource = Puppet::Type.type(:firewall_rule).new(
          name: 'SSH',
          type: 'EGRESS',
          nic_name: @nic_name,
          datacenter_name: @datacenter_name,
          server_name: @server_name,
          protocol: 'TCP',
          source_mac: '01:23:45:67:89:00',
          port_range_start: 22,
          port_range_end: 22,
        )
        @provider = provider_class.new(@resource)
        @resource2 = Puppet::Type.type(:firewall_rule).new(
          name: 'ICMP',
          type: 'INGRESS',
          nic_name: @nic_name,
          datacenter_name: @datacenter_name,
          server_name: @server_name,
          protocol: 'ICMP',
          icmp_code: 152,
          icmp_type: 87,
        )
        @provider2 = provider_class.new(@resource2)
      end
    end

    after(:all) do
      VCR.use_cassette('firewall_rule_create_cleanup') do
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Firewall_rule::ProviderV1
    end

    it 'creates IonosCloud firewall rule' do
      VCR.use_cassette('firewall_rule_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq('SSH')
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
        expect(@provider2.name).to eq('ICMP')
      end
    end

    it 'lists firewall rules' do
      VCR.use_cassette('firewall_rule_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Firewall_rule::ProviderV1
      end
    end

    it 'updates firewall rule' do
      VCR.use_cassette('firewall_rule_update') do
        @provider.target_ip = '10.81.12.124'
        @provider.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'SSH'
        end
        expect(updated_instance.target_ip).to eq('10.81.12.124')
      end
    end

    it 'deletes firewall rule' do
      VCR.use_cassette('firewall_rule_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
      end
    end
  end
end
