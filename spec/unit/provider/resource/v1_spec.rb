require 'spec_helper'

provider_class = Puppet::Type.type(:resource).provider(:v1)

describe provider_class do
  context 'resource operations' do
    it 'lists resource instances' do
      VCR.use_cassette('resource_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::Resource::ProviderV1
      end
    end
  end
end
