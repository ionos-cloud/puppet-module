require 'spec_helper'

provider_class = Puppet::Type.type(:s3_key).provider(:v1)

describe provider_class do
  context 's3_key operations' do
    it 'lists s3_key instances' do
      VCR.use_cassette('s3_key_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::S3_key::ProviderV1
      end
    end
  end
end
