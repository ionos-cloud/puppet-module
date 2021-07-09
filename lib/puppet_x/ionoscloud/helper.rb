require 'ionoscloud'

module PuppetX
  module IonoscloudX
    # Helper class for the IONOS Cloud Puppet module
    class Helper
      def self.ionoscloud_config(_depth = nil)
        Ionoscloud.configure do |config|
          config.username = ENV['IONOS_USERNAME']
          config.password = ENV['IONOS_PASSWORD']
        end
      end

      def self.count_by_name(res_name, items)
        items.count { |item| res_name == item.properties.name }
      end

      def self.resolve_datacenter_id(dc_id, dc_name)
        return dc_id unless dc_id.nil? || dc_id.empty?
        unless dc_name.nil? || dc_name.empty?
          Puppet.info('Validating if data center name is unique.')
          return datacenter_from_name(dc_name).id
        end
        raise 'Data center ID or name must be provided.'
      end

      def self.datacenter_from_name(dc_name)
        datacenters = Ionoscloud::DataCentersApi.new.datacenters_get(depth: 1)
        dc_count = count_by_name(dc_name, datacenters.items)

        raise "Found more than one data center named '#{dc_name}'." if dc_count > 1
        raise "Data center named '#{dc_name}' cannot be found." if dc_count == 0

        datacenters.items.find { |dc| dc.properties.name == dc_name }
      end

      def self.lan_from_name(lan_name, datacenter_id)
        lans = Ionoscloud::LansApi.new.datacenters_lans_get(datacenter_id, depth: 1)
        lan = lans.items.find { |lan| lan.properties.name == lan_name }
        raise "LAN named '#{lan_name}' cannot be found." unless lan
        lan
      end

      def self.volume_from_name(volume_name, datacenter_id)
        volumes = Ionoscloud::VolumesApi.new.datacenters_volumes_get(datacenter_id, depth: 1)
        volume = volumes.items.find { |volume| volume.properties.name == volume_name }
        raise "Volume named '#{volume_name}' cannot be found." unless volume
        volume
      end

      def self.server_from_name(server_name, datacenter_id)
        servers = Ionoscloud::ServersApi.new.datacenters_servers_get(datacenter_id, depth: 1)
        server = servers.items.find { |server| server.properties.name == server_name }
        raise "Server named '#{server_name}' cannot be found." unless server
        server
      end

      def self.group_from_name(group_name)
        group = Ionoscloud::UserManagementApi.new.um_groups_get(depth: 1).items.find { |group| group.properties.name == group_name }
        raise "Group named '#{group_name}' cannot be found." unless group
        group
      end

      def self.resolve_group_id(group_id, group_name)
        return group_id unless group_id.nil? || group_id.empty?
        group_from_name(group_name).id
      end

      def self.user_from_email(user_email)
        user = Ionoscloud::UserManagementApi.new.um_users_get(depth: 1).items.find { |user| user.properties.email == user_email }
        raise "User with email '#{user_email}' cannot be found." unless user
        user
      end

      def self.backup_unit_from_name(backup_unit_name)
        backup_units = Ionoscloud::BackupUnitsApi.new.backupunits_get(depth: 1)

        backup_unit = backup_units.items.find { |backup_unit| backup_unit.properties.name == backup_unit_name }
        raise "Backup unit named '#{backup_unit_name}' cannot be found." unless backup_unit
        backup_unit
      end

      def self.pcc_from_name(pcc_name)
        pccs = Ionoscloud::PrivateCrossConnectsApi.new.pccs_get(depth: 1)

        pcc = pccs.items.find { |pcc| pcc.properties.name == pcc_name }
        raise "PCC named '#{pcc_name}' cannot be found." unless pcc
        pcc
      end

      def self.cluster_from_name(cluster_name)
        clusters = Ionoscloud::KubernetesApi.new.k8s_get(depth: 1)
        cluster = clusters.items.find { |cluster| cluster.properties.name == cluster_name }
        raise "K8s cluster named '#{cluster_name}' cannot be found." unless cluster
        cluster
      end

      def self.resolve_cluster_id(cluster_id, cluster_name)
        return cluster_id unless cluster_id.nil? || cluster_id.empty?
        unless cluster_name.nil? || cluster_name.empty?
          return cluster_from_name(cluster_name).id
        end
        raise 'Cluster ID or name must be provided.'
      end

      def self.sync_cdroms(datacenter_id, server_id, existing_cdroms, target_cdroms, wait = false)
        to_detach = existing_cdroms.nil? ? [] : existing_cdroms.map { |cdrom| cdrom[:id] }
        to_wait = []

        target_cdroms.each do |target_cdrom|
          if to_detach.include? target_cdrom['id']
            to_detach.delete(target_cdrom['id'])
          else
            Puppet.info "Attaching #{target_cdrom['id']} to server"
            _, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_cdroms_post_with_http_info(
              datacenter_id, server_id, id: target_cdrom['id']
            )

            to_wait << headers
          end
        end

        to_detach.each do |cdrom_id|
          Puppet.info "Detaching #{cdrom_id} from server"
          _, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_cdroms_delete_with_http_info(
            datacenter_id, server_id, cdrom_id
          )
          to_wait << headers
        end

        return to_wait unless wait

        to_wait.each { |headers| wait_request(headers) }
        []
      end

      def self.sync_volumes(datacenter_id, server_id, existing_volumes, target_volumes, wait = false)
        existing_names = existing_volumes.nil? ? [] : existing_volumes.map { |volume| volume[:name] }

        to_detach = existing_volumes.nil? ? [] : existing_volumes.map { |volume| volume[:id] }
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
              Puppet.info "Attaching #{target_volume['id']} to server"
              _, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_volumes_post_with_http_info(
                datacenter_id, server_id, id: target_volume['id']
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
              Puppet.info "Creating volume #{target_volume} from server"

              volume, _, headers = Ionoscloud::VolumesApi.new.datacenters_volumes_post_with_http_info(
                datacenter_id, volume_object_from_hash(target_volume)
              )

              to_wait_create << [ headers, volume.id ]
            end
          end
        end

        to_detach.each do |volume_id|
          Puppet.info "Detaching #{volume_id} from server"
          _, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_volumes_delete_with_http_info(
            datacenter_id, server_id, volume_id
          )
          to_wait << headers
        end

        to_wait_create.each do |headers, volume_id|
          Puppet.info "Attaching #{volume_id} to server"
          wait_request(headers)
          _, _, new_headers = Ionoscloud::ServersApi.new.datacenters_servers_volumes_post_with_http_info(
            datacenter_id, server_id, id: volume_id
          )

          to_wait << new_headers
        end

        return to_wait unless wait

        to_wait.each { |headers| wait_request(headers) }
        []
      end

      def self.update_volume(datacenter_id, volume_id, current, target, wait = false)
        changes = Hash[*[:size].map { |v| [ v, target[v.to_s] ] }.flatten ].delete_if { |k, v| v.nil? || v == current[k] }
        return nil if changes.empty?

        raise 'Decreasing size of the volume is not allowed.' unless target['size'] > current[:size]

        changes = Ionoscloud::VolumeProperties.new(**changes)

        Puppet.info "Updating Volume #{current[:name]} with #{changes}"

        _, _, headers = Ionoscloud::VolumesApi.new.datacenters_volumes_patch_with_http_info(datacenter_id, volume_id, changes)
        wait_request(headers) if wait

        headers
      end

      def self.sync_nics(datacenter_id, server_id, existing_nics, target_nics, wait = false)
        existing_names = existing_nics.nil? ? [] : existing_nics.map { |nic| nic[:name] }

        to_delete = existing_nics.nil? ? [] : existing_nics.map { |nic| nic[:id] }
        to_wait = []

        target_nics.each do |desired_nic|
          if existing_names.include? desired_nic['name']
            existing_nic = existing_nics.find { |volume| volume[:name] == desired_nic['name'] }
            headers = update_nic(datacenter_id, server_id, existing_nic[:id], existing_nic, desired_nic)

            to_wait += headers unless headers.empty?
            to_delete.delete(existing_nic[:id])
          else
            Puppet.info "Creating NIC #{desired_nic} in server #{server_id}"

            _, _, headers = Ionoscloud::NetworkInterfacesApi.new.datacenters_servers_nics_post_with_http_info(
              datacenter_id, server_id, nic_object_from_hash(desired_nic, datacenter_id)
            )
            to_wait << headers
          end
        end

        to_delete.each do |nic_id|
          Puppet.info "Deleting NIC #{nic_id} from server #{server_id}"
          _, _, headers = Ionoscloud::NetworkInterfacesApi.new.datacenters_servers_nics_delete_with_http_info(
            datacenter_id, server_id, nic_id
          )
          to_wait << headers
        end

        to_wait.each { |headers| wait_request(headers) } if wait
        wait ? [] : to_wait
      end

      def self.update_nic(datacenter_id, server_id, nic_id, current, target, wait = false)
        firewallrules_headers = sync_firewallrules(datacenter_id, server_id, nic_id, current[:firewall_rules], target['firewall_rules'])

        changes = Hash[*[:firewall_active, :ips, :dhcp, :lan].flat_map { |v| [ v, target[v.to_s] ] } ].delete_if { |k, v| v.nil? || v == current[k] }

        if changes.empty?
          firewallrules_headers.each { |headers| wait_request(headers) } if wait
          return wait ? [] : firewallrules_headers
        end

        changes[:lan] = Integer(lan_from_name(changes[:lan], datacenter_id).id) unless changes[:lan].nil?
        changes = Ionoscloud::NicProperties.new(**changes)
        Puppet.info "Updating NIC #{current[:name]} with #{changes}"

        _, _, headers = Ionoscloud::NetworkInterfacesApi.new.datacenters_servers_nics_patch_with_http_info(datacenter_id, server_id, nic_id, changes)

        all_headers = firewallrules_headers
        all_headers << headers

        all_headers.each { |headers| wait_request(headers) } if wait
        wait ? [] : all_headers
      end

      def self.sync_firewallrules(datacenter_id, server_id, nic_id, existing_firewallrules, target_firewallrules, wait = false)
        return [] if target_firewallrules.nil?

        existing_names = existing_firewallrules.nil? ? [] : existing_firewallrules.map { |firewallrule| firewallrule[:name] }

        to_delete = existing_firewallrules.nil? ? [] : existing_firewallrules.map { |firewallrule| firewallrule[:id] }
        to_wait = []

        target_firewallrules.each do |desired_firewallrule|
          if existing_names.include? desired_firewallrule['name']
            existing_firewallrule = existing_firewallrules.find { |volume| volume[:name] == desired_firewallrule['name'] }
            headers = update_firewallrule(
              datacenter_id, server_id, nic_id, existing_firewallrule[:id], existing_firewallrule, desired_firewallrule
            )

            to_wait << headers unless headers.nil?
            to_delete.delete(existing_firewallrule[:id])
          else
            Puppet.info "Creating FirewallRule #{desired_firewallrule}"

            firewallrule = firewallrule_object_from_hash(desired_firewallrule)

            _, _, headers = Ionoscloud::FirewallRulesApi.new.datacenters_servers_nics_firewallrules_post_with_http_info(
              datacenter_id, server_id, nic_id, firewallrule
            )
            to_wait << headers
          end
        end

        to_delete.each do |firewallrule_id|
          Puppet.info "Deleting FirewallRule #{firewallrule_id}"
          _, _, headers = Ionoscloud::NetworkInterfacesApi.new.datacenters_servers_nics_firewallrules_delete_with_http_info(
            datacenter_id, server_id, nic_id, firewallrule_id
          )
          to_wait << headers
        end

        to_wait.each { |headers| wait_request(headers) } if wait
        wait ? [] : to_wait
      end

      def self.update_firewallrule(datacenter_id, server_id, nic_id, firewallrule_id, current, target, wait = false)
        changeable_fields = [:source_mac, :source_ip, :target_ip, :port_range_start, :port_range_end, :icmp_type, :icmp_code]
        changes = Hash[*changeable_fields.map { |v| [ v, target[v.to_s] ] }.flatten ].delete_if { |k, v| v.nil? || v == current[k] }
        return nil if changes.empty?

        changes = Ionoscloud::FirewallruleProperties.new(**changes)
        Puppet.info "Updating Firewall Rule #{current[:name]} with #{changes}"

        _, _, headers = Ionoscloud::FirewallRulesApi.new.datacenters_servers_nics_firewallrules_patch_with_http_info(
          datacenter_id, server_id, nic_id, firewallrule_id, changes
        )
        wait_request(headers) if wait

        headers
      end

      def self.volume_object_from_hash(volume)
        volume_config = {
          name: volume['name'],
          size: volume['size'],
          bus: volume['bus'],
          type: volume['volume_type'] || 'HDD',
          user_data: volume['user_data'],
          availability_zone: volume['availability_zone'],
          cpu_hot_plug: volume['cpu_hot_plug'],
          ram_hot_plug: volume['ram_hot_plug'],
          nic_hot_plug: volume['nic_hot_plug'],
          nic_hot_unplug: volume['nic_hot_unplug'],
          disc_virtio_hot_plug: volume['disc_virtio_hot_plug'],
          disc_virtio_hot_unplug: volume['disc_virtio_hot_unplug'],
          image_password: volume['image_password'],
          ssh_keys: volume['ssh_keys'].is_a?(Array) ? volume['ssh_keys'] : [volume['ssh_keys']],
          image: volume['image_id'],
          licence_type: volume['licence_type'],
          backupunit_id: volume['backupunit_id'],
        }

        v = Ionoscloud::Volume.new(
          properties: Ionoscloud::VolumeProperties.new(
            **(volume_config.delete_if { |_k, v| v.nil? }).transform_values { |el| el.is_a?(Symbol) ? el.to_s : el },
          ),
        )
        puts volume
        puts v
        v
      end

      def self.cdrom_object_array_from_hashes(cdroms)
        return [] if cdroms.nil?

        cdroms.map { |cdrom| Ionoscloud::Image.new(id: cdrom['id']) }
      end

      def self.nic_object_from_hash(nic, datacenter_id)
        lan = lan_from_name(nic['lan'], datacenter_id)

        nic_config = {
          name: nic['name'],
          ips: nic['ips'],
          dhcp: nic['dhcp'],
          lan: lan.id,
          firewall_active: nic['firewall_active'],
        }

        Ionoscloud::Nic.new(
          properties: Ionoscloud::NicProperties.new(
            **(nic_config.delete_if { |_k, v| v.nil? }).transform_values { |el| el.is_a?(Symbol) ? el.to_s : el },
          ),
          entities: Ionoscloud::NicEntities.new(
            firewallrules: Ionoscloud::FirewallRules.new(
              items: firewallrule_object_array_from_hashes(nic['firewall_rules']),
            ),
          ),
        )
      end

      def self.firewallrule_object_from_hash(firewallrule)
        firewallrule_config = {
          name: firewallrule['name'],
          protocol: firewallrule['protocol'],
          source_mac: firewallrule['source_mac'],
          source_ip: firewallrule['source_ip'],
          target_ip: firewallrule['target_ip'],
          port_range_start: firewallrule['port_range_start'],
          port_range_end: firewallrule['port_range_end'],
          icmp_type: firewallrule['icmp_type'],
          icmp_code: firewallrule['icmp_code'],
        }

        Ionoscloud::FirewallRule.new(
          properties: Ionoscloud::FirewallruleProperties.new(
            **(firewallrule_config.delete_if { |_k, v| v.nil? }).transform_values { |el| el.is_a?(Symbol) ? el.to_s : el },
          ),
        )
      end

      def self.volume_object_array_from_hashes(volumes)
        return [] if volumes.nil?

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

      def self.nic_object_array_from_hashes(nics, datacenter_id)
        return nics.map { |nic| nic_object_from_hash(nic, datacenter_id) } unless nics.nil?
        []
      end

      def self.peers_sync(existing_objects, target_objects, pcc_id, wait = true)
        existing = Marshal.load(Marshal.dump(existing_objects))

        headers_list = []

        target_objects.each do |target_object|
          existing_object = existing_objects.find do |object|
            (
              ((object[:name] == target_object['name']) || (object[:id] == target_object['id'])) &&
              ((object[:datacenter_name] == target_object['datacenter_name']) || (object[:datacenter_id] == target_object['datacenter_id']))
            )
          end
          if existing_object
            existing.delete(existing_object)
          else
            datacenter_id = resolve_datacenter_id(target_object['datacenter_id'], target_object['datacenter_name'])
            peer_id = target_object['id'] ? target_object['id'] : PuppetX::IonoscloudX::Helper.lan_from_name(target_object['name'], datacenter_id).id

            Puppet.info "Adding LAN #{peer_id} to PCC #{pcc_id}"
            _, _, headers = Ionoscloud::LansApi.new.datacenters_lans_patch_with_http_info(datacenter_id, peer_id, pcc: pcc_id)
            headers_list << headers
          end
        end

        existing.each do |peer|
          Puppet.info "Removing LAN #{peer[:id]} from PCC #{pcc_id}"
          _, _, headers = Ionoscloud::LansApi.new.datacenters_lans_patch_with_http_info(peer[:datacenter_id], peer[:id], pcc: nil)
          headers_list << headers
        end

        if wait
          headers_list.each { |headers| wait_request(headers) }
          []
        else
          headers_list
        end
      end

      def self.peers_match(existing_objects, target_objects)
        return true if target_objects.nil?
        return false unless existing_objects.length == target_objects.length

        existing = Marshal.load(Marshal.dump(existing_objects))

        target_objects.each do |target_object|
          existing_object = existing_objects.find do |object|
            (
              ((object[:name] == target_object['name']) || (object[:id] == target_object['id'])) &&
              ((object[:datacenter_name] == target_object['datacenter_name']) || (object[:datacenter_id] == target_object['datacenter_id']))
            )
          end
          return false unless existing_object

          existing.delete(existing_object)
        end

        existing.empty?
      end

      def self.objects_match(existing_objects, target_objects, fields_to_check)
        return true if target_objects.nil?
        return false unless existing_objects.length == target_objects.length

        existing_ids = existing_objects.map { |object| object[:id] }

        target_objects.each do |target_object|
          existing_object = existing_objects.find do |object|
            (object[:name] == target_object['name']) || (object[:id] == target_object['id'])
          end
          return false unless existing_object
          fields_to_check.each do |field|
            return false unless target_object[field.to_s].nil? || target_object[field.to_s] == existing_object[field]
          end

          if block_given?
            return false unless yield(existing_object, target_object)
          end

          existing_ids.delete(existing_object[:id])
        end

        existing_ids.empty?
      end

      def self.wait_request(headers)
        Ionoscloud::ApiClient.new.wait_for_completion(get_request_id(headers))
      end

      def self.get_request_id(headers)
        headers['Location'].scan(%r{/requests/(\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b)}).last.first
      rescue NoMethodError
        nil
      end

      def self.validate_uuid_format(uuid)
        uuid_regex = %r{^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$}
        return true if uuid_regex.match?(uuid.to_s.downcase)
        false
      end
    end
  end
end
