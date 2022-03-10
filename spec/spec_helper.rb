# frozen_string_literal: true

warn_level = $VERBOSE
$VERBOSE = nil
require 'ionoscloud'
require 'ionoscloud-dbaas-postgres'
$VERBOSE = warn_level

require 'webmock/rspec'
require 'vcr'
require 'securerandom'

require 'simplecov'
require 'simplecov_json_formatter'

SimpleCov.start do
  add_group 'Providers', 'lib/puppet/provider/'
  add_group 'Types', 'lib/puppet/type/'
  add_group 'Providers spec files', 'spec/unit/provider/'
  add_group 'Types spec files', 'spec/unit/type/'
end
SimpleCov.coverage_dir 'coverage'
SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter

RSpec.configure do |config|
  config.mock_with :rspec
end
require 'puppetlabs_spec_helper/module_spec_helper'

VCR.configure do |config|
  config.cassette_library_dir = 'fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('username') { ENV['IONOS_USERNAME'] }

  config.before_record do |rec|
    filter_headers(rec, 'Authorization', 'Basic dXNlcm5hbWU6cGFzc3dvcmQ=')

    request_url_regex = %r{/requests/(\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b)}
    rec.ignore! if request_url_regex.match?(rec.request.uri) && ['QUEUED', 'RUNNING'].include?(JSON.parse(rec.response.body)['metadata']['status'])

    k8s_cluster_url_regex = %r{/k8s/(\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b)}
    k8s_nodepool_url_regex = %r{/k8s/(\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b)/nodepools/(\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b)}

    rec.ignore! if rec.request.method == :get && k8s_cluster_url_regex.match?(rec.request.uri) && ['DEPLOYING', 'UPDATING'].include?((JSON.parse(rec.response.body)['metadata'] || {})['state'])
    rec.ignore! if rec.request.method == :get && k8s_nodepool_url_regex.match?(rec.request.uri) && ['DEPLOYING', 'UPDATING'].include?((JSON.parse(rec.response.body)['metadata'] || {})['state'])

    postgres_cluster_url_regex =%r{/clusters/(\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b)}
    rec.ignore! if rec.request.method == :get && k8s_nodepool_url_regex.match?(rec.request.uri) && ['DESTROYING', 'DEPLOYING', 'BUSY'].include?((JSON.parse(rec.response.body)['metadata'] || {})['state'])
  end
end

def ionoscloud_api_client
  api_config = Ionoscloud::Configuration.new

  api_config.username = ENV['IONOS_USERNAME']
  api_config.password = ENV['IONOS_PASSWORD']

  unless ENV['IONOS_API_URL'].nil?
    uri = URI.parse(ENV['IONOS_API_URL'])

    api_config.scheme = uri.scheme
    api_config.host = uri.host
    api_config.base_path = uri.path
    api_config.server_index = nil
  end

  api_config.debugging = ENV['IONOS_DEBUG'] || false

  api_client = Ionoscloud::ApiClient.new(api_config)

  api_client.user_agent = [
    'puppet/v5.1.0',
    api_client.default_headers['User-Agent'],
    'puppet/' + Puppet.version,
  ].join('_')

  api_client
end

def ionoscloud_dbaas_postgres_api_client
  api_config = IonoscloudDbaasPostgres::Configuration.new

  api_config.username = ENV['IONOS_USERNAME']
  api_config.password = ENV['IONOS_PASSWORD']

  unless ENV['IONOS_API_URL'].nil?
    uri = URI.parse(ENV['IONOS_API_URL'])

    api_config.scheme = uri.scheme
    api_config.host = uri.host
    api_config.base_path = uri.path
    api_config.server_index = nil
  end

  api_config.debugging = ENV['IONOS_DEBUG'] || false

  api_client = IonoscloudDbaasPostgres::ApiClient.new(api_config)

  api_client.user_agent = [
    'puppet/v5.1.0',
    api_client.default_headers['User-Agent'],
    'puppet/' + Puppet.version,
  ].join('_')

  api_client
end

def filter_headers(rec, pattern, placeholder)
  [rec.request.headers, rec.response.headers].each do |headers|
    sensitive_data = headers.select { |key| key.to_s.match(pattern) }
    sensitive_data.each do |key, _value|
      headers[key] = placeholder
    end
  end
end

def get_cluster_id(cluster_name)
  cluster = Ionoscloud::KubernetesApi.new(ionoscloud_api_client).k8s_get(depth: 1).items.find { |cluster| cluster.properties.name == cluster_name }
  cluster.id
end

def wait_cluster_active(cluster_id)
  ionoscloud_api_client.wait_for do
    cluster = Ionoscloud::KubernetesApi.new(ionoscloud_api_client).k8s_find_by_cluster_id(cluster_id)
    cluster.metadata.state == 'ACTIVE'
  end
end

def wait_nodepool_active(cluster_id, nodepool_id)
  ionoscloud_api_client.wait_for do
    cluster = Ionoscloud::KubernetesApi.new(ionoscloud_api_client).k8s_nodepools_find_by_id(cluster_id, nodepool_id)
    cluster.metadata.state == 'ACTIVE'
  end
end

def create_cluster(cluster_name)
  @cluster_provider = Puppet::Type.type(:k8s_cluster).provider(:v1).new(
    Puppet::Type.type(:k8s_cluster).new(
      name: cluster_name,
      k8s_version: '1.18.5',
      maintenance_day: 'Sunday',
      maintenance_time: '14:53:00Z',
    ),
  )

  exists = false
  Puppet::Type.type(:k8s_cluster).provider(:v1).instances.each do |cluster|
    next unless cluster.name == @cluster_provider.name
    exists = true
    id = cluster.id
    wait_cluster_active(id)
    return id
  end

  unless exists
    @cluster_provider.create
  end
  wait_cluster_active(@cluster_provider.id)
  @cluster_provider.id
end

def create_datacenter(datacenter_name)
  Puppet::Type.type(:datacenter).provider(:v1).instances.each do |instance|
    return instance.id if instance.name == datacenter_name
  end

  @datacenter_provider = Puppet::Type.type(:datacenter).provider(:v1).new(
    Puppet::Type.type(:datacenter).new(
      name: datacenter_name,
      location: 'de/txl',
      description: 'Puppet Module test description',
    ),
  )
  @datacenter_provider.create
  @datacenter_provider.id
end

def create_ipblock(ipblock_name)
  Puppet::Type.type(:ipblock).provider(:v1).instances.each do |instance|
    return instance.id if instance.name == ipblock_name
  end
  @ipblock_provider = Puppet::Type.type(:ipblock).provider(:v1).new(
    Puppet::Type.type(:ipblock).new(
      name: ipblock_name,
      location: 'de/txl',
      size: 2,
    ),
  )
  @ipblock_provider.create
  @ipblock_provider.id
end

def create_server(datacenter_name, server_name)
  @server_provider = Puppet::Type.type(:server).provider(:v1).new(
    Puppet::Type.type(:server).new(
      name: server_name,
      cores: 1,
      ram: 1024,
      availability_zone: 'ZONE_1',
      datacenter_name: datacenter_name,
      cpu_family: 'INTEL_SKYLAKE',
    ),
  )
  @server_provider.create unless @server_provider.exists?
  @server_provider.id
end

def create_nic(datacenter_name, server_name, lan_name, nic_name)
  @nic_provider = Puppet::Type.type(:nic).provider(:v1).new(
    Puppet::Type.type(:nic).new(
      name: nic_name,
      dhcp: true,
      firewall_active: true,
      server_name: server_name,
      lan: lan_name,
      datacenter_name: datacenter_name,
    ),
  )
  @nic_provider.create unless @nic_provider.exists?
  @nic_provider.id
end

def create_volume(datacenter_name, volume_name)
  @volume_provider = Puppet::Type.type(:volume).provider(:v1).new(
    Puppet::Type.type(:volume).new(
      name: volume_name,
      size: 100,
      licence_type: 'LINUX',
      volume_type: 'SSD',
      availability_zone: 'AUTO',
      datacenter_name: datacenter_name,
    ),
  )
  @volume_provider.create unless @volume_provider.exists?
  @volume_provider.id
end

def create_private_lan(datacenter_name, lan_name)
  Puppet::Type.type(:lan).provider(:v1).instances.each do |instance|
    return instance.id if instance.name == lan_name
  end
  @lan_provider = Puppet::Type.type(:lan).provider(:v1).new(
    Puppet::Type.type(:lan).new(
      name: lan_name,
      public: false,
      datacenter_name: datacenter_name,
    ),
  )
  @lan_provider.create
  @lan_provider.id
end

def create_public_lan(datacenter_name, lan_name)
  Puppet::Type.type(:lan).provider(:v1).instances.each do |instance|
    return instance.id if instance.name == lan_name
  end
  @lan_provider = Puppet::Type.type(:lan).provider(:v1).new(
    Puppet::Type.type(:lan).new(
      name: lan_name,
      public: true,
      datacenter_name: datacenter_name,
    ),
  )
  @lan_provider.create
  @lan_provider.id
end

def create_group(group_name)
  @group_provider = Puppet::Type.type(:ionoscloud_group).provider(:v1).new(
    Puppet::Type.type(:ionoscloud_group).new(
      name: group_name,
      create_data_center: true,
      create_snapshot: true,
      reserve_ip: true,
      access_activity_log: true,
      s3_privilege: true,
      create_backup_unit: true,
      create_internet_access: true,
      create_k8s_cluster: true,
      create_pcc: true,
    ),
  )
  @group_provider.create unless @group_provider.exists?
  @group_provider.id
end

def delete_group(group_name)
  @group_provider = Puppet::Type.type(:ionoscloud_group).provider(:v1).new(
    Puppet::Type.type(:ionoscloud_group).new(name: group_name),
  )
  @group_provider.destroy if @group_provider.exists?
end

def delete_cluster(cluster_name)
  @cluster_provider = Puppet::Type.type(:k8s_cluster).provider(:v1).new(
    Puppet::Type.type(:k8s_cluster).new(name: cluster_name),
  )
  @cluster_provider.destroy if @cluster_provider.exists?
end

def delete_datacenter(datacenter_name)
  @datacenter_provider = Puppet::Type.type(:datacenter).provider(:v1).new(
    Puppet::Type.type(:datacenter).new(name: datacenter_name),
  )
  @datacenter_provider.destroy if @datacenter_provider.exists?
end

def get_postgres_backup(postgres_cluster_id)
  IonoscloudDbaasPostgres::BackupsApi.new(ionoscloud_dbaas_postgres_api_client).cluster_backups_get(postgres_cluster_id).items.first
end

def wait_postgres_cluster_available(cluster_id)
  ionoscloud_dbaas_postgres_api_client.wait_for do
    IonoscloudDbaasPostgres::ClustersApi.new(ionoscloud_dbaas_postgres_api_client).clusters_find_by_id(cluster_id).metadata.state == 'AVAILABLE'
  end
end
