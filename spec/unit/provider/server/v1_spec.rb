require 'spec_helper'

provider_class = Puppet::Type.type(:server).provider(:v1)

describe provider_class do
  context 'server operations' do
    before(:all) do
      VCR.use_cassette('server_prepare') do
        @datacenter_name = 'puppet_module_test6w3g3g34g3g34g3g89g34d0ebc5ed'
        @lan_name = 'puppet_module_test6ffwedqdwfeqwfwefweg5eh4d0ebc5ed'
        create_datacenter(@datacenter_name)
        create_private_lan(@datacenter_name, @lan_name)

        @server1_name = 'puppet_module_test6ffwegwgwegwwdqw5eh4d0ebc5ed'
        @server2_name = 'puppet_module_test6ffwgwegwegwegwegewgwh4d0ebc5ed'
        @server3_name = 'puppet_module_test6ffwggergergergeadadegewgwh4d0ebc5ed'

        @resource1 = Puppet::Type.type(:server).new(
          name: @server1_name,
          cores: 1,
          ram: 1024,
          cpu_family: 'INTEL_SKYLAKE',
          availability_zone: 'ZONE_1',
          datacenter_name: @datacenter_name,
        )
        @provider1 = provider_class.new(@resource1)

        vol1 = {}
        vol1['name'] = 'Puppet Module Test'
        vol1['size'] = 15
        vol1['bus'] = 'VIRTIO'
        vol1['volume_type'] = 'HDD'
        vol1['availability_zone'] = 'AUTO'
        vol1['licence_type'] = 'LINUX'

        vol2 = {}
        vol2['name'] = 'Puppet Module Test 2'
        vol2['size'] = 10
        vol2['bus'] = 'VIRTIO'
        vol2['volume_type'] = 'HDD'
        vol2['availability_zone'] = 'ZONE_3'
        vol2['licence_type'] = 'LINUX'

        firewall = {}
        firewall['name'] = 'SSH'
        firewall['protocol'] = 'TCP'
        firewall['source_mac'] = '01:23:45:67:89:00'
        firewall['port_range_start'] = 22
        firewall['port_range_end'] = 22

        nic = {}
        nic['name'] = 'Puppet Module Test'
        nic['dhcp'] = true
        nic['lan'] = @lan_name
        nic['firewall_rules'] = [firewall]

        @resource2 = Puppet::Type.type(:server).new(
          name: @server2_name,
          cores: 1,
          cpu_family: 'INTEL_SKYLAKE',
          ram: 1024,
          volumes: [vol1, vol2],
          purge_volumes: true,
          nics: [nic],
          datacenter_name: @datacenter_name,
        )
        @provider2 = provider_class.new(@resource2)

        vol3 = {}
        vol3['name'] = 'Puppet Module Test 3'
        vol3['bus'] = 'VIRTIO'
        vol3['volume_type'] = 'DAS'
        vol3['licence_type'] = 'LINUX'

        @resource3 = Puppet::Type.type(:server).new(
          name: @server3_name,
          type: 'CUBE',
          cpu_family: 'INTEL_SKYLAKE',
          template_uuid: '15c6dd2f-02d2-4987-b439-9a58dd59ecc3',
          volumes: [vol3],
          datacenter_name: @datacenter_name,
        )
        @provider3 = provider_class.new(@resource3)
      end
    end

    after(:all) do
      VCR.use_cassette('server_cleanup') do
        delete_datacenter(@datacenter_name)
      end
    end

    it 'is an instance of the ProviderV1' do
      expect(@provider1).to be_an_instance_of Puppet::Type::Server::ProviderV1
      expect(@provider2).to be_an_instance_of Puppet::Type::Server::ProviderV1
      expect(@provider3).to be_an_instance_of Puppet::Type::Server::ProviderV1
    end

    it 'creates IonosCloud server with minimum params' do
      VCR.use_cassette('server_create_min') do
        expect(@provider1.create).to be_truthy
        expect(@provider1.exists?).to be true
        expect(@provider1.name).to eq(@server1_name)
      end
    end

    it 'creates composite server' do
      VCR.use_cassette('server_create_composite') do
        expect(@provider2.create).to be_truthy
        expect(@provider2.exists?).to be true
        expect(@provider2.name).to eq(@server2_name)
      end
    end

    it 'creates cube server' do
      VCR.use_cassette('server_create_cube') do
        expect(@provider3.create).to be_truthy
        expect(@provider3.exists?).to be true
        expect(@provider3.name).to eq(@server3_name)
      end
    end

    it 'lists server instances' do
      VCR.use_cassette('server_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Server::ProviderV1
      end
    end

    it 'updates boot volume' do
      VCR.use_cassette('server_update_boot_volume') do
        @provider2.boot_volume = 'Puppet Module Test 2'
        @provider2.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @server2_name
        end
        expect(updated_instance.boot_volume[:name]).to eq('Puppet Module Test 2')
      end
    end

    it 'updates RAM' do
      VCR.use_cassette('server_update_ram') do
        @provider2.ram = 2048
        @provider2.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @server2_name
        end
        expect(updated_instance.ram).to eq(2048)
      end
    end

    it 'updates cores' do
      VCR.use_cassette('server_update_cores') do
        @provider2.cores = 2
        @provider2.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @server2_name
        end
        expect(updated_instance.cores).to eq(2)
      end
    end

    it 'updates availability zone' do
      VCR.use_cassette('server_update_availabilty_zone') do
        @provider1.availability_zone = 'AUTO'
        @provider1.flush
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @server1_name
        end
        expect(updated_instance.availability_zone).to eq('AUTO')
      end
    end

    it 'updates server volumes' do
      VCR.use_cassette('server_update_volumes') do
        volumes = [
          {
            'name' => 'volume1',
            'volume_type' => 'HDD',
            'size' => 15,
            'licence_type' => 'LINUX',
          },
          {
            'name' => 'volume2',
            'volume_type' => 'HDD',
            'size' => 10,
            'licence_type' => 'LINUX',
          },
        ]
        @provider1.volumes = volumes
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @server1_name
        end
        expect(updated_instance.volumes.length).to eq(2)
        expect(updated_instance.volumes[1][:name]).to eq('volume1')
        expect(updated_instance.volumes[1][:size]).to eq(15)
        expect(updated_instance.volumes[0][:name]).to eq('volume2')
        expect(updated_instance.volumes[0][:size]).to eq(10)

        updated_instance.volumes = []
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @server1_name
        end
        expect(updated_instance.volumes.length).to eq(0)
      end
    end

    it 'updates server volumes 2' do
      VCR.use_cassette('server_update_volumes2') do
        volumes = [
          {
            'name' => 'Puppet Module Test',
            'volume_type' => 'HDD',
            'size' => 20,
            'licence_type' => 'LINUX',
          },
          {
            'name' => 'Puppet Module Test 3',
            'volume_type' => 'HDD',
            'size' => 10,
            'licence_type' => 'LINUX',
          },
        ]
        provider_class.instances.each do |instance|
          @provider2 = instance if instance.name == @server2_name
        end
        @provider2.volumes = volumes
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @server2_name
        end
        expect(updated_instance.volumes.length).to eq(2)
        expect(updated_instance.volumes[0][:name]).to eq('Puppet Module Test 3')
        expect(updated_instance.volumes[0][:size]).to eq(10)
        expect(updated_instance.volumes[1][:name]).to eq('Puppet Module Test')
        expect(updated_instance.volumes[1][:size]).to eq(20)
      end
    end

    it 'updates server nics' do
      VCR.use_cassette('server_update_nics') do
        nics = [
          {
            'name' => 'Puppet Module Test 2',
            'dhcp' => false,
            'lan' => @lan_name,
            'firewall_active' => true,
            'firewall_rules' => [
              {
                'name' => 'SSH2',
                'protocol' => 'TCP',
                'port_range_start' => 22,
                'port_range_end' => 22,
              },
            ]
          },
          {
            'name' => 'Puppet Module Test 3',
            'dhcp' => true,
            'lan' => @lan_name,
            'firewall_active' => false,
          },
        ]
        provider_class.instances.each do |instance|
          @provider2 = instance if instance.name == @server2_name
        end
        @provider2.nics = nics
        updated_instance = nil
        provider_class.instances.each do |instance|
          updated_instance = instance if instance.name == @server2_name
        end
        expect(updated_instance.nics.length).to eq(2)
        expect(updated_instance.nics[0][:name]).to eq('Puppet Module Test 3')
        expect(updated_instance.nics[0][:dhcp]).to eq(true)
        expect(updated_instance.nics[0][:lan]).to eq(@lan_name)
        expect(updated_instance.nics[0][:firewall_active]).to eq(false)
        expect(updated_instance.nics[0][:firewall_rules]).to eq([])

        expect(updated_instance.nics[1][:name]).to eq('Puppet Module Test 2')
        expect(updated_instance.nics[1][:dhcp]).to eq(false)
        expect(updated_instance.nics[1][:lan]).to eq(@lan_name)
        expect(updated_instance.nics[1][:firewall_active]).to eq(true)
        expect(updated_instance.nics[1][:firewall_rules].length).to eq(1)
        expect(updated_instance.nics[1][:firewall_rules][0][:name]).to eq('SSH2')
        expect(updated_instance.nics[1][:firewall_rules][0][:port_range_start]).to eq(22)
        expect(updated_instance.nics[1][:firewall_rules][0][:port_range_end]).to eq(22)
      end
    end

    it 'stops server' do
      VCR.use_cassette('server_stop') do
        expect(@provider2.running?).to be true
        expect(@provider2.stop).to be_truthy
        expect(@provider2.stopped?).to be true
      end
    end

    it 'starts server' do
      VCR.use_cassette('server_start') do
        expect(@provider2.running?).to be false
        expect(@provider2.create).to be_truthy
        expect(@provider2.running?).to be true
      end
    end

    it 'restarts server' do
      VCR.use_cassette('server_restart') do
        expect(@provider2.running?).to be true
        expect(@provider2.restart).to be_truthy
        expect(@provider2.running?).to be true
      end
    end

    it 'suspends server' do
      VCR.use_cassette('server_suspend') do
        expect(@provider3.running?).to be true
        expect(@provider3.suspend).to be_truthy
        expect(@provider3.suspended?).to be true
      end
    end

    it 'resumes server' do
      VCR.use_cassette('server_resume') do
        expect(@provider3.running?).to be false
        expect(@provider3.create).to be_truthy
        expect(@provider3.running?).to be true
      end
    end

    it 'deletes server' do
      VCR.use_cassette('server_delete') do
        expect(@provider1.destroy).to be_truthy
        expect(@provider1.exists?).to be false
        expect(@provider2.destroy).to be_truthy
        expect(@provider2.exists?).to be false
        expect(@provider3.destroy).to be_truthy
        expect(@provider3.exists?).to be false
      end
    end
  end
end
