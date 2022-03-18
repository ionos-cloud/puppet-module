require 'spec_helper'

provider_class = Puppet::Type.type(:postgres_version).provider(:v1)

describe provider_class do
  context 'postgres_version operations' do
    it 'lists postgres_version instances' do
      VCR.use_cassette('postgres_version_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Postgres_version::ProviderV1
      end
    end
  end
end
