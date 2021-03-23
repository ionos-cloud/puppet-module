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

      def self.update_volume(datacenter_id, volume_id, current, target, wait = false)
        changes = Hash[*[:size].collect {|v| [ v, target[v.to_s] ] }.flatten ].delete_if { |k, v| v.nil? || v == current[k] }
        return nil unless !changes.empty?

        puts ['facem call update!', changes].to_s

        _, _, headers = Ionoscloud::VolumeApi.new.datacenters_volumes_patch_with_http_info(datacenter_id, volume_id, changes)
        wait_request(headers) unless !wait

        return headers
      end

      def self.update_nic(datacenter_id, server_id, nic_id, current, target, wait = false)
        firewallrules_headers = sync_firewallrules(datacenter_id, server_id, nic_id, current[:firewall_rules], target['firewall_rules'])

        target['lan'] = Integer(lan_from_name(target['lan'], datacenter_id).id) unless target['lan'].nil?
        changes = Hash[*[:ips, :dhcp, :nat, :lan].collect {|v| [ v, target[v.to_s] ] }.flatten ].delete_if { |k, v| v.nil? || v == current[k] }
        return firewallrules_headers unless !changes.empty?

        puts "Updating NIC #{current[:name]} with #{changes}"

        _, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_patch_with_http_info(datacenter_id, server_id, nic_id, changes)



        all_headers = firewallrules_headers
        all_headers << headers

        all_headers.each { |headers| PuppetX::Profitbricks::Helper::wait_request(headers) } unless !wait

        return all_headers
      end

      def self.sync_firewallrules(datacenter_id, server_id, nic_id, existing_firewallrules, target_firewallrules, wait = false)
        return nil unless !target_firewallrules.nil?

        puts [datacenter_id, server_id, nic_id, existing_firewallrules, target_firewallrules].to_s

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

            firewallrule = Ionoscloud::FirewallRule.new(
              properties: Ionoscloud::FirewallruleProperties.new(
                name: desired_firewallrule['name'],
                protocol: desired_firewallrule['protocol'],
                source_mac: desired_firewallrule['source_mac'],
                source_ip: desired_firewallrule['source_ip'],
                target_ip: desired_firewallrule['target_ip'],
                port_range_start: desired_firewallrule['port_range_start'],
                port_range_end: desired_firewallrule['port_range_end'],
                icmp_type: desired_firewallrule['icmp_type'],
                icmp_code: desired_firewallrule['icmp_code'],
              ),
            )

            volume, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_firewallrules_post_with_http_info(
              datacenter_id, server_id, nic_id, nic_object_from_hash(firewallrule),
            )
            to_wait << headers
          end
        end

        puts(['to_delete', to_delete].to_s)

        to_delete.each do |firewallrule_id|
          puts "Deleting FirewallRule #{firewallrule_id}"
          _, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_firewallrules, delete_with_http_info(
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

        puts "Updating Firewall Rule #{current[:name]} with #{changes}"

        _, _, headers = Ionoscloud::NicApi.new.datacenters_servers_nics_firewallrules_patch_with_http_info(
          datacenter_id, server_id, nic_id, firewallrule_id, changes,
        )
        wait_request(headers) unless !wait

        return headers
      end

      def self.wait_request(headers)
        # begin
        Ionoscloud::ApiClient.new.wait_for_completion(get_request_id(headers))
        # rescue Ionoscloud::ApiError => err
        #   fail err.message
        # end
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
