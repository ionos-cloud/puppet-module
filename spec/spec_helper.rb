# frozen_string_literal: true

require 'ionoscloud'
require 'webmock/rspec'
require 'vcr'

RSpec.configure do |config|
  config.mock_with :rspec
end
require 'puppetlabs_spec_helper/module_spec_helper'

VCR.configure do |config|
  config.cassette_library_dir = 'fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('username') { ENV['PROFITBRICKS_USERNAME'] }

  config.before_record do |rec|
    filter_headers(rec, 'Authorization', 'Basic dXNlcm5hbWU6cGFzc3dvcmQ=')

    request_url_regex = %r{/requests/(\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b)}
    rec.ignore! if request_url_regex.match?(rec.request.uri) && ['QUEUED', 'RUNNING'].include?(JSON.parse(rec.response.body)['metadata']['status'])

    k8s_cluster_url_regex = %r{/k8s/(\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b)}
    rec.ignore! if rec.request.method == :get && k8s_cluster_url_regex.match?(rec.request.uri) && ['DEPLOYING', 'UPDATING'].include?((JSON.parse(rec.response.body)['metadata'] || {})['state'])
  end
end

Ionoscloud.configure do |config|
  config.username = ENV['IONOS_USERNAME']
  config.password = ENV['IONOS_PASSWORD']
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
  cluster = Ionoscloud::KubernetesApi.new.k8s_get(depth: 1).items.find { |cluster| cluster.properties.name == cluster_name }
  cluster.id
end

def wait_cluster_active(cluster_id)
  Ionoscloud::ApiClient.new.wait_for do
    cluster = Ionoscloud::KubernetesApi.new.k8s_find_by_cluster_id(cluster_id)
    cluster.metadata.state == 'ACTIVE'
  end
end

def wait_nodepool_active(cluster_id, nodepool_id)
  Ionoscloud::ApiClient.new.wait_for do
    cluster = Ionoscloud::KubernetesApi.new.k8s_nodepools_find_by_id(cluster_id, nodepool_id)
    cluster.metadata.state == 'ACTIVE'
  end
end
