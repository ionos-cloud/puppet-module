require 'profitbricks'
require 'ionoscloud'


module PuppetX
  module Profitbricks
    class Helper
      def self.profitbricks_config(depth = nil)
        ProfitBricks.configure do |config|
          config.username = ENV['PROFITBRICKS_USERNAME']
          config.password = ENV['PROFITBRICKS_PASSWORD']
          config.timeout = 600

          config.depth = depth unless depth.nil?

          url = ENV['PROFITBRICKS_API_URL']
          config.url = url unless url.nil? || url.empty?

          config.headers = Hash.new
          config.headers['User-Agent'] = "Puppet/#{Puppet.version}"
        end
        Ionoscloud.configure do |config|
          config.username = ENV['PROFITBRICKS_USERNAME']
          config.password = ENV['PROFITBRICKS_PASSWORD']
        end
      end

      def self.count_by_name(res_name, items)
        begin
          items.count { |item| res_name.strip.downcase == item.properties.name.strip.downcase }
        rescue Exception
          count = 0
          unless items.empty?
            name_key = res_name.strip.downcase
            items.each do |item|
              unless item.properties['name'].nil? || item.properties['name'].empty?
                item_name = item.properties['name'].strip.downcase
                count += 1 if item_name == name_key
              end
            end
          end
          count
        end
      end

      def self.resolve_datacenter_id(dc_id, dc_name)
        return dc_id unless dc_id.nil? || dc_id.empty?
        unless dc_name.nil? || dc_name.empty?
          Puppet.info("Validating if data center name is unique.")
          return datacenter_from_name(dc_name).id
        end
        fail "Data center ID or name must be provided."
      end

      def self.datacenter_from_name(dc_name)
        datacenters = Ionoscloud::DataCenterApi.new.datacenters_get({ depth: 1 })
        dc_count = count_by_name(dc_name, datacenters.items)
    
        fail "Found more than one data center named '#{dc_name}'." if dc_count > 1
        fail "Data center named '#{dc_name}' cannot be found." if dc_count == 0
    
        datacenters.items.find { |dc| dc.properties.name == dc_name }
      end

      def self.lan_from_name(lan_name, datacenter_id)
        lan = LAN.list(datacenter_id).find { |lan| lan.properties['name'] == lan_name }
        fail "LAN named '#{lan_name}' cannot be found." unless lan
        lan
      end

      def self.server_from_name(server_name, datacenter_id)
        server = Server.list(datacenter_id).find { |server| server.properties['name'] == server_name }
        fail "Server named '#{server_name}' cannot be found." unless server
        server
      end

      def self.group_from_name(group_name)
        group = Group.list.find { |group| group.properties['name'] == group_name }
        fail "Group named '#{group_name}' cannot be found." unless group
        group
      end

      def self.resolve_group_id(group_id, group_name)
        return group_id unless group_id.nil? || group_id.empty?
        return group_from_name(group_name).id
      end

      def self.user_from_name(user_email)
        user = User.list.find { |user| user.properties['email'] == user_email }
        fail "User with email '#{user_email}' cannot be found." unless user
        user
      end

      def self.sync_volumes(datacenter_id, server_id, existing_volumes, target_volumes, wait = false)
        existing_names = existing_volumes.map { |volume| volume[:name] }
    
        to_detach = existing_volumes.map { |volume| volume[:id] }
        to_wait = []
        to_wait_create = []
    
        target_volumes.each do |target_volume|
          if target_volume['id']
            if to_detach.include? target_volume['id']
              existing_volume = existing_volumes.find { |volume| volume[:id] == target_volume['id'] }
              headers = update_volume(datacenter_id, existing_volume[:id], existing_volume, target_volume)
              
              to_wait << headers unless headers.nil?
    
              to_detach.delete(existing_volume[:id])
            else
              puts "Attaching #{target_volume['id']} to server"
              _, _, headers = Ionoscloud::ServerApi.new.datacenters_servers_volumes_post_with_http_info(
                datacenter_id, server_id, id: target_volume['id'],
              )
    
              to_wait << headers
            end
          elsif target_volume['name']
            if existing_names.include? target_volume['name']
              existing_volume = existing_volumes.find { |volume| volume[:name] == target_volume['name'] }
    
              headers = update_volume(datacenter_id, existing_volume[:id], existing_volume, target_volume)
              
              to_wait << headers unless headers.nil?
    
              to_detach.delete(existing_volume[:id])
            else
              puts "Creating volume #{target_volume} from server"
    
              volume, _, headers = Ionoscloud::VolumeApi.new.datacenters_volumes_post_with_http_info(
                datacenter_id, volume_object_from_hash(target_volume),
              )
    
              to_wait_create << [ headers, volume.id ]
            end
          end
        end
    
        to_detach.each do |volume_id|
          puts "Detaching #{volume_id} from server"
          _, _, headers = Ionoscloud::ServerApi.new.datacenters_servers_volumes_delete_with_http_info(
            datacenter_id, server_id, volume_id,
          )
          to_wait << headers
        end
    
        to_wait_create.each do |headers, volume_id|
          puts "Attaching #{volume_id} to server"
          wait_request(headers)
          _, _, new_headers = Ionoscloud::ServerApi.new.datacenters_servers_volumes_post_with_http_info(
            datacenter_id, server_id, id: volume_id,
          )
    
          to_wait << new_headers
        end

        return to_wait unless wait
    
        to_wait.each { |headers| wait_request(headers) }
      end

      def self.update_volume(datacenter_id, volume_id, current, target, wait = false)
        changes = Hash[*[:size].collect {|v| [ v, target[v.to_s] ] }.flatten ].delete_if { |k, v| v.nil? || v == current[k] }
        return nil unless !changes.empty?

        changes = Ionoscloud::VolumeProperties.new(**changes)

        puts "Updating Volume #{current[:name]} with #{changes}"

        _, _, headers = Ionoscloud::VolumeApi.new.datacenters_volumes_patch_with_http_info(datacenter_id, volume_id, changes)
        wait_request(headers) unless !wait

        return headers
      end

      def self.sync_nics(datacenter_id, server_id, existing_nics, target_nics, wait = false)
        existing_names = existing_nics.map { |nic| nic[:name] }
    
        to_delete = existing_nics.map { |nic| nic[:id] }
        to_wait = []
        to_wait_create = []
    
        target_nics.each do |desired_nic|
          if existing_names.include? desired_nic['name']
            existing_nic = existing_nics.find { |volume| volume[:name] == desired_nic['name'] }
            headers = update_nic(datacenter_id, server_id, existing_nic[:id], existing_nic, desired_nic)
            
            to_wait += headers unless headers.empty?
            to_delete.delete(existing_nic[:id])
          else
            puts "Creating NIC #{desired_nic} in server #{@property_hash[:name]}"
    
            volume, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_post_with_http_info(
              datacenter_id, server_id, nic_object_from_hash(desired_nic),
            )
            to_wait << headers
          end
        end
    
        to_delete.each do |nic_id|
          puts "Deleting NIC #{nic_id} from server #{@property_hash[:name]}"
          _, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_delete_with_http_info(
            datacenter_id, server_id, nic_id,
          )
          to_wait << headers
        end
    
        to_wait.each { |headers| wait_request(headers) }
      end

      def self.update_nic(datacenter_id, server_id, nic_id, current, target, wait = false)
        firewallrules_headers = sync_firewallrules(datacenter_id, server_id, nic_id, current[:firewall_rules], target['firewall_rules'])

        changes = Hash[*[:firewall_active, :ips, :dhcp, :nat, :lan].collect {|v| [ v, target[v.to_s] ] }.flatten ].delete_if { |k, v| v.nil? || v == current[k] }
        return firewallrules_headers unless !changes.empty?

        changes[:lan] = Integer(lan_from_name(changes[:lan], datacenter_id).id) unless changes[:lan].nil?
        changes = Ionoscloud::NicProperties.new(**changes)
        puts "Updating NIC #{current[:name]} with #{changes}"

        _, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_patch_with_http_info(datacenter_id, server_id, nic_id, changes)

        all_headers = firewallrules_headers
        all_headers << headers

        all_headers.each { |headers| wait_request(headers) } unless !wait

        return all_headers
      end

      def self.sync_firewallrules(datacenter_id, server_id, nic_id, existing_firewallrules, target_firewallrules, wait = false)
        return [] unless !target_firewallrules.nil?

        existing_names = existing_firewallrules.map { |firewallrule| firewallrule[:name] }

        to_delete = existing_firewallrules.map { |firewallrule| firewallrule[:id] }
        to_wait = []
        to_wait_create = []

        target_firewallrules.each do |desired_firewallrule|
          if existing_names.include? desired_firewallrule['name']
            existing_firewallrule = existing_firewallrules.find { |volume| volume[:name] == desired_firewallrule['name'] }
            headers =  update_firewallrule(
              datacenter_id, server_id, nic_id, existing_firewallrule[:id], existing_firewallrule, desired_firewallrule,
            )

            to_wait << headers unless headers.nil?
            to_delete.delete(existing_firewallrule[:id])
          else
            puts "Creating FirewallRule #{desired_firewallrule}"

            firewallrule = firewallrule_object_from_hash(desired_firewallrule)

            volume, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_firewallrules_post_with_http_info(
              datacenter_id, server_id, nic_id, firewallrule,
            )
            to_wait << headers
          end
        end

        to_delete.each do |firewallrule_id|
          puts "Deleting FirewallRule #{firewallrule_id}"
          _, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_firewallrules_delete_with_http_info(
            datacenter_id, server_id, nic_id, firewallrule_id,
          )
          to_wait << headers
        end

        return to_wait
      end

      def self.update_firewallrule(datacenter_id, server_id, nic_id, firewallrule_id, current, target, wait = false)
        changeable_fields = [:source_mac, :source_ip, :target_ip, :port_range_start, :port_range_end, :icmp_type, :icmp_code]
        changes = Hash[*changeable_fields.collect {|v| [ v, target[v.to_s] ] }.flatten ].delete_if { |k, v| v.nil? || v == current[k] }
        return nil unless !changes.empty?

        changes = Ionoscloud::FirewallruleProperties.new(**changes)
        puts "Updating Firewall Rule #{current[:name]} with #{changes}"

        _, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_firewallrules_patch_with_http_info(
          datacenter_id, server_id, nic_id, firewallrule_id, changes,
        )
        wait_request(headers) unless !wait

        return headers
      end

      def self.volume_object_from_hash(volume)
        config = {
          name: volume['name'],
          size: volume['size'],
          bus: volume['bus'],
          type: volume['volume_type'] || 'HDD',
          availability_zone: volume['availability_zone'],
        }

        if volume.key?('image_password')
          config[:image_password] = volume['image_password']
        elsif volume.key?('ssh_keys')
          config[:sshKeys] = volume['ssh_keys'].is_a?(Array) ? volume['ssh_keys'] : [volume['ssh_keys']]
        else
          fail('Volume must have either image_password or ssh_keys defined.')
        end

        if volume.key?('image_id')
          config[:image] = volume['image_id']
        elsif volume.key?('image_alias')
          config[:image_alias] = volume['image_alias']
        else
          fail('Volume must have either image_id or image_alias defined.')
        end

        Ionoscloud::Volume.new(properties: Ionoscloud::VolumeProperties.new(**config))
      end

      def nic_object_from_hash(nic)
        lan = lan_from_name(nic['lan'], resolve_datacenter_id(resource[:datacenter_id], resource[:datacenter_name]))
    
        Ionoscloud::Nic.new(
          properties: Ionoscloud::NicProperties.new(
            name: nic['name'],
            ips: nic['ips'],
            dhcp: nic['dhcp'],
            lan: lan.id,
            nat: nic['nat'],
            firewall_active: nic['firewall_active'],
          ),
          entities: Ionoscloud::NicEntities.new(
            firewallrules: Ionoscloud::FirewallRules.new(
              items: firewallrule_object_array_from_hashes(nic['firewall_rules']),
            ),
          ),
        )
      end

      def firewallrule_object_from_hash(firewallrule)
        Ionoscloud::FirewallRule.new(
          properties: Ionoscloud::FirewallruleProperties.new(
            name: firewallrule['name'],
            protocol: firewallrule['protocol'],
            source_mac: firewallrule['source_mac'],
            source_ip: firewallrule['source_ip'],
            target_ip: firewallrule['target_ip'],
            port_range_start: firewallrule['port_range_start'],
            port_range_end: firewallrule['port_range_end'],
            icmp_type: firewallrule['icmp_type'],
            icmp_code: firewallrule['icmp_code'],
          ),
        )
      end

      def self.volume_object_array_from_hashes(volumes)
        return [] unless !volumes.nil?
    
        volumes.map do |volume|
          if volume['id'].nil?
            volume_object_from_hash(volume)
          else
            Ionoscloud::Volume.new(id: volume['id'])
          end
        end
      end
    
      def self.firewallrule_object_array_from_hashes(fwrules)
        return fwrules.map { |fwrule| firewallrule_object_from_hash(fwrule) } unless fwrules.nil?
        []
      end
    
      def self.nic_object_array_from_hashes(nics)
        return nics.map { |nic| nic_object_from_hash(nic) } unless nics.nil?
        []
      end

      def self.objects_match(existing_objects, target_objects, fields_to_check)
        return true if target_objects.nil?
        return false unless existing_objects.length == target_objects.length
   
        existing_ids = existing_objects.map { |object| object[:id] }
  
        target_objects.each do |target_object|
          existing_object = existing_objects.find do
            |object|
            (object[:name] == target_object['name']) || (object[:id] == target_object['id'])
          end
          return false unless existing_object
          fields_to_check.each do
            |field|
            return false unless (target_object[field.to_s].nil? || target_object[field.to_s] == existing_object[field])
          end

          if block_given?
            return false unless yield(existing_object, target_object)
          end
  
          existing_ids.delete(existing_object[:id])
        end
  
        return existing_ids.empty?
      end

      def self.wait_request(headers)
        Ionoscloud::ApiClient.new.wait_for_completion(get_request_id(headers))
      end

      def self.get_request_id(headers)
        begin
          headers['Location'].scan(%r{/requests/(\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b)}).last.first
        rescue NoMethodError
          nil
        end
      end
    end
  end
end
