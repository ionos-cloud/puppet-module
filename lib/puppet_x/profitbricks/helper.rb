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

      def self.update_volume(datacenter_id, volume_id, current, result, wait = false)
        changeable_properties = [:size]

        puts [current, result].to_s

        changes = Hash[*changeable_properties.collect {|v| [ v, result[v.to_s] ] }.flatten ].delete_if { |k, v| v.nil? || v == current[k] }

        return nil unless !changes.empty?

        puts ['facem call update!', changes].to_s
        
        _, _, headers = Ionoscloud::VolumeApi.new.datacenters_volumes_patch_with_http_info(datacenter_id, volume_id, changes)

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
