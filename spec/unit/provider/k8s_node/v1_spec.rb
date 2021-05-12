require 'spec_helper'

provider_class = Puppet::Type.type(:k8s_node).provider(:v1)

describe provider_class do
  context 'k8s node operations' do
    it 'lists k8s_node instances' do
      VCR.use_cassette('k8s_node_list') do
        instances = provider_class.instances
        expect(instances.length).to be > 0
        expect(instances[0]).to be_an_instance_of Puppet::Type::K8s_node::ProviderV1
      end
    end
  end
end
