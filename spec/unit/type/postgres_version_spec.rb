require 'spec_helper'

type_class = Puppet::Type.type(:postgres_version)

describe type_class do
  let :params do
    [
      :name,
    ]
  end

  it 'has expected parameters' do
    params.each do |param|
      expect(type_class.parameters).to be_include(param)
    end
  end

  it 'requires a name' do
    expect {
      type_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
end
