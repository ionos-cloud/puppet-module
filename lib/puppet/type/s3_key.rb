Puppet::Type.newtype(:s3_key) do
  @doc = 'Type representing an s3 key'

  newparam(:name, namevar: true) do
    desc 'The id of the s3 key.'

    def insync?(is)
      true
    end
  end

  newproperty(:user_id) do
    desc 'The ID of the user.'
    validate do |value|
      fail('the user ID must be a String') unless value.is_a?(String)
    end

    def insync?(is)
      true
    end
  end

  newproperty(:user_email) do
    desc 'The email of the user.'
    validate do |value|
      fail('the user email must be a String') unless value.is_a?(String)
    end

    def insync?(is)
      true
    end
  end

  newproperty(:secret_key) do
    desc 'The secret key.'
    validate do |value|
      fail('the secret key be a String') unless value.is_a?(String)
    end

    def insync?(is)
      true
    end
  end

  newproperty(:active) do
    desc 'The ID of the user.'
    newvalues(:true, :false)

    def insync?(is)
      true
    end
  end
end