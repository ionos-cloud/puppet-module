require 'puppetlabs_spec_helper/module_spec_helper'
require 'webmock/rspec'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data('username') { ENV['PROFITBRICKS_USERNAME'] }

  config.before_record do |rec|
    filter_headers(rec, 'Authorization', 'Basic dXNlcm5hbWU6cGFzc3dvcmQ=')

    uuid_regex = %r{/requests/(\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b)}
    rec.ignore! if uuid_regex.match?(rec.request.uri) && ['QUEUED', 'RUNNING'].include?(JSON.parse(rec.response.body)['metadata']['status'])
  end
end

def filter_headers(rec, pattern, placeholder)
  [rec.request.headers, rec.response.headers].each do |headers|
    sensitive_data = headers.select { |key| key.to_s.match(pattern) }
    sensitive_data.each do |key, _value|
      headers[key] = placeholder
    end
  end
end
