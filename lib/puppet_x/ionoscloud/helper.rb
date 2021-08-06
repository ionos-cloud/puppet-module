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

      def self.sync_objects(existing, target, aux_args, update_method, create_method, delete_method, wait = false, id_field = :name)
        return [] if target.nil?

        existing_names = existing.nil? ? [] : existing.map { |obj| obj[id_field] }

        to_delete = existing.nil? ? [] : existing.map { |obj| obj[:id] }
        to_wait = []

        target.each do |desired_obj|
          if existing_names.include? desired_obj[id_field.to_s]
            existing_obj = existing.find { |obj| obj[id_field] == desired_obj[id_field.to_s] }
            headers = public_send(update_method, *aux_args, existing_obj[:id], existing_obj, desired_obj)

            to_wait += headers unless headers.empty?
            to_delete.delete(existing_obj[:id])
          else
            _, headers = public_send(create_method, *aux_args, desired_obj)
            to_wait << headers
          end
        end

        to_delete.each do |object_id|
          to_wait << public_send(delete_method, *aux_args, object_id)
        end

        to_wait.each { |headers| wait_request(headers) } if wait
        wait ? [] : to_wait
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

      def self.update_natgateway_rule(datacenter_id, natgateway_id, natgateway_rule_id, current, target, wait = false)
        changeable_fields = [:protocol, :public_ip, :source_subnet, :target_subnet, :target_port_range]
        changes = Hash[*changeable_fields.flat_map { |v| [ v, target[v.to_s] ] } ].delete_if { |k, v| v.nil? || compare_objects(current[k], v) }
        return [] if changes.empty?

        changes[:protocol] = current[:protocol] if changes[:protocol].nil?

        changes = Ionoscloud::NatGatewayRuleProperties.new(**changes)
        Puppet.info "Updating NAT Gateway Rule #{current[:name]} with #{changes}"

        _, _, headers = Ionoscloud::NATGatewaysApi.new.datacenters_natgateways_rules_patch_with_http_info(
          datacenter_id, natgateway_id, natgateway_rule_id, changes
        )
        wait_request(headers) if wait

        [headers]
      end

      def self.create_natgateway_rule(datacenter_id, natgateway_id, desired_natgateway_rule, wait = false)
        Puppet.info "Creating NAT Gateway Rule #{desired_natgateway_rule}"

        natgateway_rule = natgateway_rule_object_from_hash(desired_natgateway_rule)

        natgateway_rule, _, headers = Ionoscloud::NATGatewaysApi.new.datacenters_natgateways_rules_post_with_http_info(
          datacenter_id, natgateway_id, natgateway_rule
        )
        wait_request(headers) if wait

        [natgateway_rule, headers]
      end

      def self.delete_natgateway_rule(datacenter_id, natgateway_id, natgateway_rule_id, wait = false)
        Puppet.info "Deleting NAT Gateway Rule #{natgateway_rule_id}"
        _, _, headers = Ionoscloud::NATGatewaysApi.new.datacenters_natgateways_rules_delete_with_http_info(
          datacenter_id, natgateway_id, natgateway_rule_id
        )
        wait_request(headers) if wait

        headers
      end

      def self.update_networkloadbalancer_rule(datacenter_id, networkloadbalancer_id, networkloadbalancer_rule_id, current, target, wait = false)
        changeable_fields = [:algorithm, :protocol, :listener_ip, :listener_port, :health_check, :targets]

        changes = Hash[*changeable_fields.flat_map { |v| [ v, target[v.to_s] ] } ].delete_if { |k, v| v.nil? || compare_objects(current[k], v) }
        return [] if changes.empty?

        unless changes[:health_check].nil?
          changes[:health_check] = Ionoscloud::NetworkLoadBalancerForwardingRuleHealthCheck.new(
            client_timeout: changes[:health_check]['client_timeout'],
            connect_timeout: changes[:health_check]['connect_timeout'],
            target_timeout: changes[:health_check]['target_timeout'],
            retries: changes[:health_check]['retries'],
          )
        end

        unless changes[:targets].nil?
          changes[:targets] = changes[:targets].map do |target|
            Ionoscloud::NetworkLoadBalancerForwardingRuleTarget.new(
              ip: target['ip'],
              port: target['port'],
              weight: target['weight'],
              health_check: if target['health_check'].nil?
                              nil
                            else
                              Ionoscloud::NetworkLoadBalancerForwardingRuleTargetHealthCheck.new(
                                            check: target['health_check']['check'],
                                            check_interval: target['health_check']['check_interval'],
                                            maintenance: target['health_check']['maintenance'],
                                          )
                            end,
            )
          end
        end

        changes = Ionoscloud::NetworkLoadBalancerForwardingRuleProperties.new(**changes)
        Puppet.info "Updating Network Load Balancer Rule #{current[:name]} with #{changes}"

        _, _, headers = Ionoscloud::NetworkLoadBalancersApi.new.datacenters_networkloadbalancers_forwardingrules_patch_with_http_info(
          datacenter_id, networkloadbalancer_id, networkloadbalancer_rule_id, changes
        )
        wait_request(headers) if wait

        [headers]
      end

      def self.create_networkloadbalancer_rule(datacenter_id, networkloadbalancer_id, desired_networkloadbalancer_rule, wait = false)
        Puppet.info "Creating Network Load Balancer Rule #{desired_networkloadbalancer_rule}"

        networkloadbalancer_rule = networkloadbalancer_rule_object_from_hash(desired_networkloadbalancer_rule)

        networkloadbalancer_rule, _, headers = Ionoscloud::NetworkLoadBalancersApi.new.datacenters_networkloadbalancers_forwardingrules_post_with_http_info(
          datacenter_id, networkloadbalancer_id, networkloadbalancer_rule
        )
        wait_request(headers) if wait

        [networkloadbalancer_rule, headers]
      end

      def self.delete_networkloadbalancer_rule(datacenter_id, networkloadbalancer_id, networkloadbalancer_rule_id, wait = false)
        Puppet.info "Deleting Network Load Balancer Rule #{networkloadbalancer_rule_id}"
        _, _, headers = Ionoscloud::NetworkLoadBalancersApi.new.datacenters_networkloadbalancers_forwardingrules_delete_with_http_info(
          datacenter_id, networkloadbalancer_id, networkloadbalancer_rule_id
        )
        wait_request(headers) if wait

        headers
      end

      def self.update_application_loadbalancer_rule(datacenter_id, application_loadbalancer_id, application_loadbalancer_rule_id, current, target, wait = false)
        changeable_fields = [:protocol, :listener_ip, :listener_port, :health_check, :server_certificates, :http_rules]

        changes = Hash[*changeable_fields.flat_map { |v| [ v, target[v.to_s] ] } ].delete_if { |k, v| v.nil? || compare_objects(current[k], v) }
        return [] if changes.empty?

        unless changes[:health_check].nil?
          changes[:health_check] = Ionoscloud::ApplicationLoadBalancerForwardingRuleHealthCheck.new(
            client_timeout: changes[:health_check]['client_timeout'],
          )
        end

        unless changes[:http_rules].nil?
          changes[:http_rules] = changes[:http_rules].map do |rule|
            Ionoscloud::ApplicationLoadBalancerHttpRule.new(
              name: rule['name'],
              type: rule['type'],
              target_group: rule['target_group'],
              drop_query: rule['drop_query'],
              location: rule['location'],
              status_code: rule['status_code'],
              response_message: rule['response_message'],
              content_type: rule['content_type'],
              
              conditions: if rule['conditions'].nil?
                              nil
                           else
                             rule['conditions'].map do |condition|
                              Ionoscloud::ApplicationLoadBalancerHttpRuleCondition.new(
                               type: condition['type'],
                               condition: condition['condition'],
                               negate: condition['negate'],
                               key: condition['key'],
                               value: condition['value'],
                             )
                             end
                           end,
            )
          end
        end

        changes = Ionoscloud::ApplicationLoadBalancerForwardingRuleProperties.new(**changes)
        Puppet.info "Updating Network Load Balancer Rule #{current[:name]} with #{changes}"

        _, _, headers = Ionoscloud::ApplicationLoadBalancersApi.new.datacenters_applicationloadbalancers_forwardingrules_patch_with_http_info(
          datacenter_id, application_loadbalancer_id, application_loadbalancer_rule_id, changes
        )
        wait_request(headers) if wait

        [headers]
      end

      def self.create_application_loadbalancer_rule(datacenter_id, application_loadbalancer_id, desired_application_loadbalancer_rule, wait = false)
        Puppet.info "Creating Network Load Balancer Rule #{desired_application_loadbalancer_rule}"

        application_loadbalancer_rule = application_loadbalancer_rule_object_from_hash(desired_application_loadbalancer_rule)

        application_loadbalancer_rule, _, headers = Ionoscloud::ApplicationLoadBalancersApi.new.datacenters_applicationloadbalancers_forwardingrules_post_with_http_info(
          datacenter_id, application_loadbalancer_id, application_loadbalancer_rule
        )
        wait_request(headers) if wait

        [application_loadbalancer_rule, headers]
      end

      def self.delete_application_loadbalancer_rule(datacenter_id, application_loadbalancer_id, application_loadbalancer_rule_id, wait = false)
        Puppet.info "Deleting Network Load Balancer Rule #{application_loadbalancer_rule_id}"
        _, _, headers = Ionoscloud::ApplicationLoadBalancersApi.new.datacenters_applicationloadbalancers_forwardingrules_delete_with_http_info(
          datacenter_id, application_loadbalancer_id, application_loadbalancer_rule_id
        )
        wait_request(headers) if wait

        headers
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

      def self.update_cdrom(*_args)
        []
      end

      def self.detach_cdrom(datacenter_id, server_id, cdrom_id, wait = false)
        Puppet.info "Detaching #{cdrom_id} from server"
        _, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_cdroms_delete_with_http_info(
          datacenter_id, server_id, cdrom_id
        )
        wait_request(headers) if wait

        headers
      end

      def self.attach_cdrom(datacenter_id, server_id, target_cdrom)
        Puppet.info "Attaching #{target_cdrom['id']} to server"
        cdrom, _, headers = Ionoscloud::ServersApi.new.datacenters_servers_cdroms_post_with_http_info(
          datacenter_id, server_id, id: target_cdrom['id']
        )
        [cdrom, headers]
      end

      def self.update_nic(datacenter_id, server_id, nic_id, current, target, wait = false)
        entities_headers = sync_objects(
          current[:firewall_rules], target['firewall_rules'], [datacenter_id, server_id, nic_id],
          :update_firewallrule, :create_firewallrule, :delete_firewallrule
        )

        entities_headers += sync_objects(
          current[:flowlogs], target['flowlogs'], [:nic, datacenter_id, server_id, nic_id],
          :update_flowlog, :create_flowlog, :delete_flowlog
        )

        changes = Hash[*[:firewall_active, :ips, :dhcp, :lan, :firewall_type].flat_map { |v| [ v, target[v.to_s] ] } ].delete_if { |k, v| v.nil? || v == current[k] }

        if changes.empty?
          entities_headers.each { |headers| wait_request(headers) } if wait
          return wait ? [] : entities_headers
        end

        changes[:lan] = Integer(lan_from_name(changes[:lan], datacenter_id).id) unless changes[:lan].nil?
        changes = Ionoscloud::NicProperties.new(**changes)
        Puppet.info "Updating NIC #{current[:name]} with #{changes}"

        _, _, headers = Ionoscloud::NetworkInterfacesApi.new.datacenters_servers_nics_patch_with_http_info(datacenter_id, server_id, nic_id, changes)

        all_headers = entities_headers
        all_headers << headers

        all_headers.each { |headers| wait_request(headers) } if wait
        wait ? [] : all_headers
      end

      def self.create_nic(datacenter_id, server_id, desired_nic, wait = false)
        Puppet.info "Creating NIC #{desired_nic}"

        nic = nic_object_from_hash(desired_nic, datacenter_id)

        nic, _, headers = Ionoscloud::NetworkInterfacesApi.new.datacenters_servers_nics_post_with_http_info(
          datacenter_id, server_id, nic
        )
        wait_request(headers) if wait

        [nic, headers]
      end

      def self.delete_nic(datacenter_id, server_id, nic_id, wait = false)
        Puppet.info "Deleting NIC #{nic_id}"
        _, _, headers = Ionoscloud::NetworkInterfacesApi.new.datacenters_servers_nics_delete_with_http_info(
          datacenter_id, server_id, nic_id
        )
        wait_request(headers) if wait

        headers
      end

      def self.update_firewallrule(datacenter_id, server_id, nic_id, firewallrule_id, current, target, wait = false)
        changeable_fields = [:type, :source_mac, :source_ip, :target_ip, :port_range_start, :port_range_end, :icmp_type, :icmp_code]
        changes = Hash[*changeable_fields.flat_map { |v| [ v, target[v.to_s] ] } ].delete_if { |k, v| v.nil? || v == current[k] }
        return [] if changes.empty?

        changes = Ionoscloud::FirewallruleProperties.new(**changes)
        Puppet.info "Updating Firewall Rule #{current[:name]} with #{changes}"

        _, _, headers = Ionoscloud::FirewallRulesApi.new.datacenters_servers_nics_firewallrules_patch_with_http_info(
          datacenter_id, server_id, nic_id, firewallrule_id, changes
        )
        wait_request(headers) if wait

        [headers]
      end

      def self.create_firewallrule(datacenter_id, server_id, nic_id, desired_firewallrule, wait = false)
        Puppet.info "Creating FirewallRule #{desired_firewallrule}"

        firewallrule = firewallrule_object_from_hash(desired_firewallrule)

        firewallrule, _, headers = Ionoscloud::FirewallRulesApi.new.datacenters_servers_nics_firewallrules_post_with_http_info(
          datacenter_id, server_id, nic_id, firewallrule
        )
        wait_request(headers) if wait

        [firewallrule, headers]
      end

      def self.delete_firewallrule(datacenter_id, server_id, nic_id, firewallrule_id, wait = false)
        Puppet.info "Deleting FirewallRule #{firewallrule_id}"
        _, _, headers = Ionoscloud::FirewallRulesApi.new.datacenters_servers_nics_firewallrules_delete_with_http_info(
          datacenter_id, server_id, nic_id, firewallrule_id
        )
        wait_request(headers) if wait

        headers
      end

      def self.update_flowlog(type, *args, **kwargs)
        case type
        when :nic
          current = args[4]
          target = args[5]
        else
          current = args[3]
          target = args[4]
        end

        changeable_fields = [:action, :bucket, :direction]
        changes = Hash[*changeable_fields.flat_map { |v| [ v, target[v.to_s] ] } ].delete_if { |k, v| v.nil? || v == current[k] }

        return [] if changes.empty?

        changes = Ionoscloud::FlowLogProperties.new(**changes)
        Puppet.info "Updating FlowLog #{current[:name]} with #{changes}"

        case type
        when :nic
          _, _, headers = Ionoscloud::FlowLogsApi.new.datacenters_servers_nics_flowlogs_patch_with_http_info(*args[0..3], changes)
        when :natgateway
          _, _, headers = Ionoscloud::NATGatewaysApi.new.datacenters_natgateways_flowlogs_patch_with_http_info(*args[0..2], changes)
        when :networkloadbalancer
          _, _, headers = Ionoscloud::NetworkLoadBalancersApi.new.datacenters_networkloadbalancers_flowlogs_patch_with_http_info(*args[0..2], changes)
        else
          return []
        end

        wait_request(headers) if kwargs[:wait]

        [headers]
      end

      def self.create_flowlog(type, *args, **kwargs)
        desired_flowlog = type == :nic ? args[4] : args[3]

        Puppet.info "Creating FlowLog #{desired_flowlog}"

        flowlog = flowlog_object_from_hash(desired_flowlog)

        case type
        when :nic
          flowlog, _, headers = Ionoscloud::FlowLogsApi.new.datacenters_servers_nics_flowlogs_post_with_http_info(*args[0..2], flowlog)
        when :natgateway
          flowlog, _, headers = Ionoscloud::NATGatewaysApi.new.datacenters_natgateways_flowlogs_post_with_http_info(*args[0..1], flowlog)
        when :networkloadbalancer
          flowlog, _, headers = Ionoscloud::NetworkLoadBalancersApi.new.datacenters_networkloadbalancers_flowlogs_post_with_http_info(*args[0..1], flowlog)
        else
          return
        end

        wait_request(headers) if kwargs[:wait]

        [flowlog, headers]
      end

      def self.delete_flowlog(type, *args, **kwargs)
        case type
        when :nic
          Puppet.info "Deleting FlowLog #{args[3]}"
          _, _, headers = Ionoscloud::FlowLogsApi.new.datacenters_servers_nics_flowlogs_delete_with_http_info(*args)
        when :natgateway
          Puppet.info "Deleting FlowLog #{args[2]}"

          _, _, headers = Ionoscloud::NATGatewaysApi.new.datacenters_natgateways_flowlogs_delete_with_http_info(*args)
        when :networkloadbalancer
          Puppet.info "Deleting FlowLog #{args[2]}"
          _, _, headers = Ionoscloud::NetworkLoadBalancersApi.new.datacenters_networkloadbalancers_flowlogs_delete_with_http_info(*args)
        else
          return
        end

        wait_request(headers) if kwargs[:wait]

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
        Ionoscloud::Volume.new(
          properties: Ionoscloud::VolumeProperties.new(
            **(volume_config.delete_if { |_k, v| v.nil? }).transform_values { |el| el.is_a?(Symbol) ? el.to_s : el },
          ),
        )
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
          firewall_type: nic['firewall_type'],
        }

        Ionoscloud::Nic.new(
          properties: Ionoscloud::NicProperties.new(
            **(nic_config.delete_if { |_k, v| v.nil? }).transform_values { |el| el.is_a?(Symbol) ? el.to_s : el },
          ),
          entities: Ionoscloud::NicEntities.new(
            firewallrules: Ionoscloud::FirewallRules.new(
              items: firewallrule_object_array_from_hashes(nic['firewall_rules']),
            ),
            flowlogs: Ionoscloud::FlowLogs.new(
              items: flowlog_object_array_from_hashes(nic['flowlogs']),
            ),
          ),
        )
      end

      def self.natgateway_rule_object_from_hash(natgateway_rule)
        natgateway_rule_config = {
          name: natgateway_rule['name'],
          protocol: natgateway_rule['protocol'],
          public_ip: natgateway_rule['public_ip'],
          source_subnet: natgateway_rule['source_subnet'],
          target_subnet: natgateway_rule['target_subnet'],
          target_port_range: if natgateway_rule['target_port_range'].nil?
                               nil
                             else
                               Ionoscloud::TargetPortRange.new(
                                         start: natgateway_rule['target_port_range']['start'],
                                         _end: natgateway_rule['target_port_range']['end'],
                                       )
                             end,
        }

        Ionoscloud::NatGatewayRule.new(
          properties: Ionoscloud::NatGatewayRuleProperties.new(
            **(natgateway_rule_config.delete_if { |_k, v| v.nil? }).transform_values { |el| el.is_a?(Symbol) ? el.to_s : el },
          ),
        )
      end

      def self.networkloadbalancer_rule_object_from_hash(networkloadbalancer_rule)
        networkloadbalancer_rule_config = {
          name: networkloadbalancer_rule['name'],
          algorithm: networkloadbalancer_rule['algorithm'],
          protocol: networkloadbalancer_rule['protocol'],
          listener_ip: networkloadbalancer_rule['listener_ip'],
          listener_port: networkloadbalancer_rule['listener_port'],
          health_check: if networkloadbalancer_rule['health_check'].nil?
                          nil
                        else
                          Ionoscloud::NetworkLoadBalancerForwardingRuleHealthCheck.new(
                                    client_timeout: networkloadbalancer_rule['health_check']['client_timeout'],
                                    connect_timeout: networkloadbalancer_rule['health_check']['connect_timeout'],
                                    target_timeout: networkloadbalancer_rule['health_check']['target_timeout'],
                                    retries: networkloadbalancer_rule['health_check']['retries'],
                                  )
                        end,
          targets: if networkloadbalancer_rule['targets'].nil?
                     nil
                   else
                     networkloadbalancer_rule['targets'].map do |target|
                       Ionoscloud::NetworkLoadBalancerForwardingRuleTarget.new(
                         ip: target['ip'],
                         port: target['port'],
                         weight: target['weight'],
                         health_check: if target['health_check'].nil?
                                         nil
                                       else
                                         Ionoscloud::NetworkLoadBalancerForwardingRuleTargetHealthCheck.new(
                                                       check: target['health_check']['check'],
                                                       check_interval: target['health_check']['check_interval'],
                                                       maintenance: target['health_check']['maintenance'],
                                                     )
                                       end,
                       )
                     end
                   end,
        }

        Ionoscloud::NetworkLoadBalancerForwardingRule.new(
          properties: Ionoscloud::NetworkLoadBalancerForwardingRuleProperties.new(
            **(networkloadbalancer_rule_config.delete_if { |_k, v| v.nil? }).transform_values { |el| el.is_a?(Symbol) ? el.to_s : el },
          ),
        )
      end


      def self.applicationloadbalancer_rule_object_from_hash(applicationloadbalancer_rule)
        applicationloadbalancer_rule_config = {
          name: applicationloadbalancer_rule['name'],
          protocol: applicationloadbalancer_rule['protocol'],
          listener_ip: applicationloadbalancer_rule['listener_ip'],
          listener_port: applicationloadbalancer_rule['listener_port'],
          health_check: if applicationloadbalancer_rule['health_check'].nil?
                          nil
                        else
                          Ionoscloud::ApplicationLoadBalancerForwardingRuleHealthCheck.new(
                                    client_timeout: applicationloadbalancer_rule['health_check']['client_timeout'],
                                  )
                        end,
          server_certificates: applicationloadbalancer_rule['server_certificates'],
          http_rules: if applicationloadbalancer_rule['http_rules'].nil?
                     nil
                   else
                     applicationloadbalancer_rule['http_rules'].map do |rule|
                       Ionoscloud::ApplicationLoadBalancerHttpRule.new(
                         name: rule['name'],
                         type: rule['type'],
                         target_group: rule['target_group'],
                         drop_query: rule['drop_query'],
                         location: rule['location'],
                         status_code: rule['status_code'],
                         response_message: rule['response_message'],
                         content_type: rule['content_type'],
                         
                         conditions: if rule['conditions'].nil?
                                         nil
                                      else
                                        rule['conditions'].map do |condition|
                                         Ionoscloud::ApplicationLoadBalancerHttpRuleCondition.new(
                                          type: condition['type'],
                                          condition: condition['condition'],
                                          negate: condition['negate'],
                                          key: condition['key'],
                                          value: condition['value'],
                                        )
                                        end
                                      end,
                       )
                     end
                   end,
        }

        Ionoscloud::ApplicationLoadBalancerForwardingRule.new(
          properties: Ionoscloud::ApplicationLoadBalancerForwardingRuleProperties.new(
            **(applicationloadbalancer_rule_config.delete_if { |_k, v| v.nil? }).transform_values { |el| el.is_a?(Symbol) ? el.to_s : el },
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

      def self.flowlog_object_from_hash(flowlog)
        flowlog_config = {
          name: flowlog['name'],
          action: flowlog['action'],
          bucket: flowlog['bucket'],
          direction: flowlog['direction'],
        }

        Ionoscloud::FlowLog.new(
          properties: Ionoscloud::FlowLogProperties.new(
            **(flowlog_config.delete_if { |_k, v| v.nil? }).transform_values { |el| el.is_a?(Symbol) ? el.to_s : el },
          ),
        )
      end

      def self.flowlog_object_array_from_hashes(flowlogs)
        return flowlogs.map { |flowlog| flowlog_object_from_hash(flowlog) } unless flowlogs.nil?
        []
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

      def self.natgateway_rule_object_array_from_hashes(natgateway_rules)
        return natgateway_rules.map { |natgateway_rule| natgateway_rule_object_from_hash(natgateway_rule) } unless natgateway_rules.nil?
        []
      end

      def self.networkloadbalancer_rule_object_array_from_hashes(networkloadbalancer_rules)
        unless networkloadbalancer_rules.nil?
          return networkloadbalancer_rules.map do |networkloadbalancer_rule|
            networkloadbalancer_rule_object_from_hash(networkloadbalancer_rule)
          end
        end
        []
      end

      def self.applicationloadbalancer_rule_object_array_from_hashes(applicationloadbalancer_rules)
        unless applicationloadbalancer_rules.nil?
          return applicationloadbalancer_rules.map do |applicationloadbalancer_rule|
            applicationloadbalancer_rule_object_from_hash(applicationloadbalancer_rule)
          end
        end
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

      def self.compare_objects(existing, target)
        return false if existing.class != target.class

        case existing
        when Array
          return false if existing.length != target.length
          existing_copy = Marshal.load(Marshal.dump(existing))
          target_copy = Marshal.load(Marshal.dump(target))

          begin
            existing_copy = existing_copy.sort
            target_copy = target_copy.sort
          rescue
            begin
              comp = ->(a, b) { a['name'] <=> b['name'] }
              existing_copy = existing_copy.sort(&comp)
              target_copy = target_copy.sort(&comp)
            rescue
              begin
                comp = ->(a, b) { a['ip'] <=> b['ip'] }
                existing_copy = existing_copy.sort(&comp)
                target_copy = target_copy.sort(&comp)
              rescue StandardError => e
                raise e
              end
            end
          end
          existing_copy.zip(target_copy).each do |e, t|
            return false unless compare_objects(e, t)
          end
          true
        when Hash
          return false if target.keys.map { |key| existing.keys.include? key.to_sym }.include? false

          target.each_key do |key|
            return false unless compare_objects(existing[key.to_sym], target[key])
          end
          true
        else
          existing == target
        end
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
            next if target_object[field.to_s].nil?
            return false unless compare_objects(existing_object[field], target_object[field.to_s])
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
