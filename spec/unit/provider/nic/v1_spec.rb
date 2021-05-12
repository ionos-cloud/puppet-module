require 'spec_helper'

provider_class = Puppet::Type.type(:nic).provider(:v1)

describe provider_class do
  context 'NIC operations' do
    before(:all) do
      @resource = Puppet::Type.type(:nic).new(
        name: 'Puppet Module Test',
        lan: 'Puppet Module Test',
        dhcp: true,
        datacenter_name: 'Puppet Module Test',
        server_name: 'Puppet Module Test',
        firewall_active: true,
      )
      @provider = provider_class.new(@resource)
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Nic::ProviderV1
    end

    it 'creates ProfitBricks NIC' do
      VCR.use_cassette('nic_create') do
        expect(@provider.create).to be_truthy
        expect(@provider.exists?).to be true
        expect(@provider.name).to eq('Puppet Module Test')
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
        @provider.ips = ['158.222.102.161', '158.222.102.164']
        @provider.flush
        @provider.instance_variable_set(:@property_flush, {})
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == 'Puppet Module Test'
        end
        expect(updated_instance.dhcp).to eq(false)
        expect(updated_instance.ips.length).to eq(2)
        expect(updated_instance.ips).to include('158.222.102.161', '158.222.102.164')
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
          updated_instance = instance if instance.name == 'Puppet Module Test'
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
