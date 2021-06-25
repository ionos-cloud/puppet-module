require 'spec_helper'

provider_class = Puppet::Type.type(:nic).provider(:v1)

describe provider_class do
  context 'NIC operations' do
    before(:all) do
      VCR.use_cassette('nic_prepare') do
        @datacenter_name = 'puppet_module_test6ffnfqwfqwfqfqwfd0ebc5ed'
        @server_name = 'puppet_module_test6f2c9fwfewfewddsgh5eh4d0ebc5ed'
        @lan_name = 'puppet_module_test6f2cfwefwefwefwf5eh4d0ebc5ed'

        @ipblock_name = 'puppet_module_test6f2c9fewfewfgddqdqwdqw4d0ebc5ed'

        @ipblock_provider = Puppet::Type.type(:ipblock).provider(:v1).new(
          Puppet::Type.type(:ipblock).new(
            name: @ipblock_name,
            size: 2,
            location: 'us/las',
          ),
        )
        @ipblock_provider.create unless @ipblock_provider.exists?

        Puppet::Type.type(:ipblock).provider(:v1).instances.each do |instance|
          @ip_block = instance if instance.name == @ipblock_name
        end

        create_datacenter(@datacenter_name)
        create_server(@datacenter_name, @server_name)
        create_private_lan(@datacenter_name, @lan_name)

        @nic_name = 'puppet_module_test6f2c9f7a9afewfwefwh4d0ebc5ed'

        @resource = Puppet::Type.type(:nic).new(
          name: @nic_name,
          datacenter_name: @datacenter_name,
          server_name: @server_name,
          lan: @lan_name,
          dhcp: true,
          firewall_active: true,
        )
        @provider = provider_class.new(@resource)
      end
    end

    after(:all) do
      VCR.use_cassette('nic_cleanup') do
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Nic::ProviderV1
    end

    it 'creates IonosCloud NIC' do
      VCR.use_cassette('nic_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq(@nic_name)
      end
    end

    it 'lists NIC instances' do
      VCR.use_cassette('nic_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Nic::ProviderV1
      end
    end

    it 'updates NIC' do
      VCR.use_cassette('nic_update') do
        @provider.dhcp = false
        @provider.ips = [@ip_block.ips[0], @ip_block.ips[1]]
        @provider.flush
        @provider.instance_variable_set(:@property_flush, {})
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @nic_name
        end
        expect(updated_instance.dhcp).to eq(false)
        expect(updated_instance.ips.length).to eq(2)
        expect(updated_instance.ips).to include(@ip_block.ips[0], @ip_block.ips[1])
      end
    end

    it 'updates NIC firewallrules' do
      VCR.use_cassette('nic_update_firewallrules') do
        firewall_rules = [
          {
            'name' => 'SSH',
            'protocol' => 'TCP',
            'port_range_start' => 22,
            'port_range_end' => 22,
          },
          {
            'name' => 'HTTP',
            'protocol' => 'TCP',
            'port_range_start' => 65,
            'port_range_end' => 80
          },
        ]
        @provider.firewall_rules = firewall_rules
        @provider.flush
        @provider.instance_variable_set(:@property_flush, {})
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @nic_name
        end
        expect(updated_instance.firewall_rules.length).to eq(2)
        expect(updated_instance.firewall_rules[1][:name]).to eq('SSH')
        expect(updated_instance.firewall_rules[1][:port_range_start]).to eq(22)
        expect(updated_instance.firewall_rules[1][:port_range_end]).to eq(22)
        expect(updated_instance.firewall_rules[0][:name]).to eq('HTTP')
        expect(updated_instance.firewall_rules[0][:port_range_start]).to eq(65)
        expect(updated_instance.firewall_rules[0][:port_range_end]).to eq(80)
      end
    end

    it 'deletes NIC' do
      VCR.use_cassette('nic_delete') do
        expect(@provider.destroy).to be_truthy
        expect(@provider.exists?).to be false
      end
    end
  end
end
