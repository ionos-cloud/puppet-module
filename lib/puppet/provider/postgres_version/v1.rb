require 'puppet_x/ionoscloud/helper'

Puppet::Type.type(:postgres_version).provide(:v1) do
  confine feature: :ionoscloud

  mk_resource_methods

  def self.instances
    postgres_versions = []

    PuppetX::IonoscloudX::Helper.dbaas_postgres_cluster_api.postgres_versions_get(depth: 1).data.each do |postgres_version|
      postgres_versions << new(instance_to_hash(postgres_version))
    end
    postgres_versions.flatten
  end

  def self.instance_to_hash(instance)
    {
      name: instance.name,
    }
  end
end
