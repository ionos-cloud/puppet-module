Puppet::Type.newtype(:postgres_version) do
  @doc = 'Type representing a Postgres Version'
  @doc_directory = 'dbaas-postgres'

  newparam(:name, namevar: true) do
    desc 'The name of the Postgres Version.'

    def insync?(_is)
      true
    end
  end
end
