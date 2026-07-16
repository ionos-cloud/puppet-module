require 'puppet_x/ionoscloud/helper'

described_class = PuppetX::IonoscloudX::Helper

describe described_class do
  describe '#ionoscloud_api_client URL scheme validation' do
    let(:mock_api_client) do
      double('Ionoscloud::ApiClient',
             default_headers: { 'User-Agent' => 'ionoscloud-ruby/6.1.0' },
             'user_agent=' => nil)
    end

    before(:each) do
      allow(Ionoscloud::ApiClient).to receive(:new).and_return(mock_api_client)
      allow(Puppet).to receive(:version).and_return('7.0.0')
      ENV['IONOS_TOKEN'] = 'test-token'
    end

    after(:each) do
      ENV.delete('IONOS_API_URL')
      ENV.delete('IONOS_TOKEN')
    end

    it 'accepts a valid HTTPS URL without raising an error' do
      ENV['IONOS_API_URL'] = 'https://api.ionos.com/cloudapi/v6'
      expect { described_class.ionoscloud_api_client }.not_to raise_error
    end

    it 'raises Puppet::Error for an HTTP URL' do
      ENV['IONOS_API_URL'] = 'http://api.ionos.com/cloudapi/v6'
      expect { described_class.ionoscloud_api_client }.to raise_error(Puppet::Error, /IONOS_API_URL must use HTTPS/)
    end

    it 'raises Puppet::Error for an ftp:// URL' do
      ENV['IONOS_API_URL'] = 'ftp://api.ionos.com/cloudapi/v6'
      expect { described_class.ionoscloud_api_client }.to raise_error(Puppet::Error, /IONOS_API_URL must use HTTPS/)
    end

    it 'skips scheme validation when IONOS_API_URL is not set' do
      ENV.delete('IONOS_API_URL')
      expect { described_class.ionoscloud_api_client }.not_to raise_error
    end
  end

  describe '#log_debug' do
    after(:each) do
      ENV.delete('IONOS_TOKEN')
      ENV.delete('IONOS_USERNAME')
      ENV.delete('IONOS_PASSWORD')
    end

    it 'redacts IONOS_TOKEN value in debug output' do
      ENV['IONOS_TOKEN'] = 'super-secret-token'
      expect(Puppet).to receive(:debug).with('[REDACTED]')
      described_class.send(:log_debug, 'super-secret-token')
    end

    it 'redacts IONOS_USERNAME value in debug output' do
      ENV['IONOS_USERNAME'] = 'testuser@example.com'
      expect(Puppet).to receive(:debug).with('[REDACTED]')
      described_class.send(:log_debug, 'testuser@example.com')
    end

    it 'redacts IONOS_PASSWORD value in debug output' do
      ENV['IONOS_PASSWORD'] = 'sekr3tpassword'
      expect(Puppet).to receive(:debug).with('[REDACTED]')
      described_class.send(:log_debug, 'sekr3tpassword')
    end

    it 'passes non-credential messages through unchanged' do
      expect(Puppet).to receive(:debug).with('non-sensitive message')
      described_class.send(:log_debug, 'non-sensitive message')
    end
  end


  describe '#sync_objects' do
    it 'calls nothing and return [] if target is nil' do
      existing = []
      target = nil
      aux_args = []

      expect(described_class).not_to receive(:wait_request)

      ret = nil
      expect { ret = described_class.sync_objects(existing, target, aux_args, :invalid_method, :invalid_method, :invalid_method) }.not_to raise_error(Exception)
      expect(ret).to eq([])
    end

    it 'calls nothing when existing and target are []' do
      existing = []
      target = []
      aux_args = []

      expect(described_class).not_to receive(:wait_request)

      ret = nil
      expect { ret = described_class.sync_objects(existing, target, aux_args, :invalid_method, :invalid_method, :invalid_method) }.not_to raise_error(Exception)
      expect(ret).to eq([])
    end

    it 'calls create' do
      existing = []
      target = [{ 'name' => 'test', 'extra' => 'test_extra' }]
      aux_args = ['test1', 'test2']

      expect(described_class).not_to receive(:wait_request)
      expect(described_class).to receive(:create_empty).once do |*args|
        expect(args).to eq(aux_args + target)
        ['id', 'test']
      end

      ret = nil
      expect { ret = described_class.sync_objects(existing, target, aux_args, :invalid_method, :create_empty, :invalid_method) }.not_to raise_error(Exception)
      expect(ret).to eq(['test'])
    end

    it 'calls update' do
      existing = [{ id: 'id', name: 'test', extra: 'test_extra_old' }]
      target = [{ 'name' => 'test', 'extra' => 'test_extra' }]
      aux_args = ['test1', 'test2']

      expect(described_class).not_to receive(:wait_request)
      expect(described_class).to receive(:update_empty).once do |*args|
        expect(args).to eq(aux_args + ['id'] + existing + target)
        ['test']
      end

      ret = nil
      expect { ret = described_class.sync_objects(existing, target, aux_args, :update_empty, :invalid_method, :invalid_method) }.not_to raise_error(Exception)
      expect(ret).to eq(['test'])
    end

    it 'calls delete' do
      existing = [{ id: 'id', name: 'test', extra: 'test_extra_old' }]
      target = []
      aux_args = ['test1', 'test2']

      expect(described_class).not_to receive(:wait_request)
      expect(described_class).to receive(:delete_empty).once do |*args|
        expect(args).to eq(aux_args + ['id'])
        'test'
      end

      ret = nil
      expect { ret = described_class.sync_objects(existing, target, aux_args, :invalid_method, :invalid_method, :delete_empty) }.not_to raise_error(Exception)
      expect(ret).to eq(['test'])
    end

    it 'calls all methods' do
      existing = [{ id: 'id', name: 'test', extra: 'test_extra_old' }, { id: 'id2', name: 'test2', extra: 'test_extra_old2' }]
      target = [{ 'name' => 'test2', 'extra' => 'test_extra4' }, { 'name' => 'test3', 'extra' => 'test_extra3' }]
      aux_args = ['test_id1', 'test_id2']

      expect(described_class).not_to receive(:wait_request)
      expect(described_class).to receive(:create_empty).once do |*args|
        expect(args).to eq(aux_args + [target[1]])
        ['create_id', 'create_test']
      end
      expect(described_class).to receive(:update_empty).once do |*args|
        expect(args).to eq(aux_args + [existing[1][:id]] + [existing[1]] + [target[0]])
        ['update_test']
      end
      expect(described_class).to receive(:delete_empty).once do |*args|
        expect(args).to eq(aux_args + [existing[0][:id]])
        'delete_test'
      end

      ret = nil
      expect { ret = described_class.sync_objects(existing, target, aux_args, :update_empty, :create_empty, :delete_empty) }.not_to raise_error(Exception)
      expect(ret).to eq(['update_test', 'create_test', 'delete_test'])
    end

    it 'calls all methods using custom field' do
      existing = [{ id: 'id', custom_name: 'test', extra: 'test_extra_old' }, { id: 'id2', custom_name: 'test2', extra: 'test_extra_old2' }]
      target = [{ 'custom_name' => 'test2', 'extra' => 'test_extra4' }, { 'custom_name' => 'test3', 'extra' => 'test_extra3' }]
      aux_args = ['test_id1', 'test_id2']

      expect(described_class).not_to receive(:wait_request)
      expect(described_class).to receive(:create_empty).once do |*args|
        expect(args).to eq(aux_args + [target[1]])
        ['create_id', 'create_test']
      end
      expect(described_class).to receive(:update_empty).once do |*args|
        expect(args).to eq(aux_args + [existing[1][:id]] + [existing[1]] + [target[0]])
        ['update_test']
      end
      expect(described_class).to receive(:delete_empty).once do |*args|
        expect(args).to eq(aux_args + [existing[0][:id]])
        'delete_test'
      end
      ret = nil
      expect { ret = described_class.sync_objects(existing, target, aux_args, :update_empty, :create_empty, :delete_empty, false, :custom_name) }.not_to raise_error(Exception)
      expect(ret).to eq(['update_test', 'create_test', 'delete_test'])
    end
  end

  describe '#compare_objects' do
    it 'returns false when existing and target are different' do
      values = [
        [
          [],
          nil,
        ],
        [
          'name',
          'name2',
        ],
        [
          10,
          100,
        ],
        [
          [],
          nil,
        ],
        [
          {},
          'string',
        ],
        [
          ['value'],
          [],
        ],
        [
          ['value'],
          ['value1'],
        ],
        [
          ['value'],
          ['value1', 'value1'],
        ],
        [
          { 'field' => 'value' },
          { 'name' => 'value' },
        ],
        [
          { 'name' => 'value' },
          { 'name' => 'value' },
        ],
        [
          { name: 'value1' },
          { 'name' => 'value' },
        ],
        [
          { name: ['value2'] },
          { 'name' => ['value'] },
        ],
        [
          [
            {
              name: 'nume1',
              type: 'REDIRECT',
              drop_query:  true,
              location: 'www.ionos.com',
              status_code:  303,
              conditions:  [
                {
                  type: 'header',
                  condition: 'starts-with',
                  negate:  true,
                  key: 'forward-at',
                  value: 'Friday',
                },
              ],
            },
            {
              name: 'nume2',
              type: 'STATIC',
              status_code:  303,
              response_message: 'Application Down',
              content_type: 'text/html',
              conditions:  [
                {
                  type: 'query',
                  condition: 'starts-with',
                  negate:  true,
                  key: 'forward-at',
                  value: 'Friday',
                },
              ],
            },
          ],
          [
            {
              'name' => 'nume2',
              'type' => 'STATIC',
              'status_code' => 303,
              'response_message' => 'Application Down',
              'content_type' => 'text/html',
              'conditions' => [
                {
                  'type' => 'query',
                  'condition' => 'starts-with',
                  'negate' => true,
                  'key' => 'forward-at',
                  'value' => 'Friday',
                },
              ],
            },
            {
              'name' => 'nume1',
              'type' => 'REDIRECT',
              'drop_query' => true,
              'location' => 'www.ionos.com',
              'status_code' => 303,
              'conditions' => [
                {
                  'type' => 'header',
                  'condition' => 'starts-with',
                  'negate' => true,
                  'key' => 'forward-at',
                  'value' => 'Friday2',
                },
              ],
            },
          ],
        ],
        [
          [
            {
              name: 'nume1',
              type: 'REDIRECT',
              drop_query:  true,
              location: 'www.ionos.com',
              status_code:  303,
              conditions:  [
                {
                  type: 'header',
                  condition: 'starts-with',
                  negate:  true,
                  key: 'forward-at',
                  value: 'Friday',
                },
              ],
            },
            {
              name: 'nume2',
              type: 'STATIC',
              status_code:  303,
              response_message: 'Application Down',
              content_type: 'text/html',
              conditions:  [
                {
                  type: 'query',
                  condition: 'starts-with',
                  negate:  true,
                  key: 'forward-at',
                  value: 'Friday',
                },
              ],
            },
          ],
          [
            {
              'name' => 'nume2',
              'type' => 'STATIC',
              'status_code' => 303,
              'response_message' => 'Application Down',
              'content_type' => 'text/html',
              'conditions' => [
                {
                  'type' => 'query',
                  'condition' => 'starts-with',
                  'negate' => true,
                  'key' => 'forward-at',
                  'value' => 'Friday',
                },
              ],
            },
            {
              'name' => 'nume1',
              'type' => 'REDIRECT',
              'drop_query' => true,
              'location' => 'www.ionos.com',
              'status_code' => 302,
              'conditions' => [
                {
                  'type' => 'header',
                  'condition' => 'starts-with',
                  'negate' => true,
                  'key' => 'forward-at',
                  'value' => 'Friday',
                },
              ],
            },
          ],
        ],
        [
          [
            {
              name: 'nume1',
              type: 'REDIRECT',
              drop_query:  true,
              location: 'www.ionos.com',
              status_code:  303,
              conditions:  [
                {
                  type: 'header',
                  condition: 'starts-with',
                  negate:  true,
                  key: 'forward-at',
                  value: 'Friday',
                },
              ],
            },
            {
              name: 'nume2',
              type: 'STATIC',
              status_code:  303,
              response_message: 'Application Down',
              content_type: 'text/html',
              conditions:  [
                {
                  type: 'query',
                  condition: 'starts-with',
                  negate:  true,
                  key: 'forward-at',
                  value: 'Friday',
                },
              ],
            },
          ],
        ],
        [
          [
            {
              unknown_key: 'nume1',
            },
            {
              unknown_key: 'nume2',
            },
          ],
          [
            {
              'unknown_key' => 'nume2',
            },
            {
              'unknown_key' => 'nume1',
            },
          ],
        ],
      ]

      values.each do |existing, target|
        expect([existing, target, described_class.compare_objects(existing, target)]).to eq([existing, target, false])
      end
    end

    it 'returns true when existing and target are the same' do
      values = [
        [
          [],
          [],
        ],
        [
          'name',
          'name',
        ],
        [
          10,
          10,
        ],
        [
          {},
          {},
        ],
        [
          { any_key: 'any_value' },
          {},
        ],
        [
          ['value'],
          ['value'],
        ],
        [
          ['value', 'value1'],
          ['value1', 'value'],
        ],
        [
          { name: 'value' },
          { 'name' => 'value' },
        ],
        [
          { name: ['value2', 'value'] },
          { 'name' => ['value', 'value2'] },
        ],
        [
          [
            {
              name: 'nume2',
              type: 'STATIC',
              status_code:  303,
              response_message: 'Application Down',
              content_type: 'text/html',
              conditions:  [
                {
                  type: 'query',
                  condition: 'starts-with',
                  negate:  true,
                  key: 'forward-at',
                  value: 'Friday',
                },
              ],
            },
            {
              name: 'nume1',
              type: 'REDIRECT',
              drop_query:  true,
              location: 'www.ionos.com',
              status_code:  303,
              conditions:  [
                {
                  type: 'header',
                  condition: 'starts-with',
                  negate:  true,
                  key: 'forward-at',
                  value: 'Friday',
                },
              ],
            },
          ],
          [
            {
              'name' => 'nume1',
              'type' => 'REDIRECT',
              'drop_query' => true,
              'location' => 'www.ionos.com',
              'status_code' => 303,
              'conditions' => [
                {
                  'type' => 'header',
                  'condition' => 'starts-with',
                  'negate' => true,
                  'key' => 'forward-at',
                  'value' => 'Friday',
                },
              ],
            },
            {
              'name' => 'nume2',
              'type' => 'STATIC',
              'status_code' => 303,
              'response_message' => 'Application Down',
              'content_type' => 'text/html',
              'conditions' => [
                {
                  'type' => 'query',
                  'condition' => 'starts-with',
                  'negate' => true,
                  'key' => 'forward-at',
                  'value' => 'Friday',
                },
              ],
            },
          ],
        ],
        [
          [
            {
              ip: 'nume1',
            },
            {
              ip: 'nume2',
            },
          ],
          [
            {
              'ip' => 'nume2',
            },
            {
              'ip' => 'nume1',
            },
          ],
        ],
      ]

      values.each do |existing, target|
        expect([existing, target, described_class.compare_objects(existing, target)]).to eq([existing, target, true])
      end
    end
  end

  describe '#objects_match' do
    it 'returns true when target_objects is nil' do
      values = [
        [
          [],
          nil,
          [],
        ],
        [
          nil,
          nil,
          [],
        ],
      ]

      values.each do |existing, target, fields_to_check|
        expect([existing, target, described_class.objects_match(existing, target, fields_to_check)]).to eq([existing, target, true])
      end
    end

    it 'returns false when existing_objects and target_objects have different lengths' do
      values = [
        [
          [],
          [{ 'name': 'test' }],
          [],
        ],
        [
          [{ name: 'test' }, { name: 'test' }],
          [{ 'name' => 'test' }],
          [],
        ],
      ]

      values.each do |existing, target, fields_to_check|
        expect([existing, target, described_class.objects_match(existing, target, fields_to_check)]).to eq([existing, target, false])
      end
    end

    it 'returns false when an object from target_objects does not exist in existing_objects' do
      values = [
        [
          [{ name: 'test2', id: 'id' }],
          [{ 'name' => 'test' }],
          [],
        ],
        [
          [{ name: 'test', id: 'id' }],
          [{ 'id' => 'id2' }],
          [],
        ],
      ]

      values.each do |existing, target, fields_to_check|
        expect([existing, target, described_class.objects_match(existing, target, fields_to_check)]).to eq([existing, target, false])
      end
    end

    it 'returns false when an object from existing_objects does not exist in target_objects' do
      values = [
        [
          [{ name: 'test2', id: 'id' }, { name: 'test', id: 'id' }],
          [{ 'name' => 'test' }],
          [],
        ],
        [
          [{ name: 'test', id: 'id' }, { name: 'test2', id: 'id2' }],
          [{ 'id' => 'id2' }],
          [],
        ],
      ]

      values.each do |existing, target, fields_to_check|
        expect([existing, target, described_class.objects_match(existing, target, fields_to_check)]).to eq([existing, target, false])
      end
    end

    it 'returns false when some specified fields to not match' do
      values = [
        [
          [{ name: 'test', id: 'id', key: 'value1' }],
          [{ 'name' => 'test', 'key' => 'value2' }],
          [:key],
        ],
        [
          [{ name: 'test', id: 'id', key: 'value1', key2: 'value1' }],
          [{ 'name' => 'test', 'key' => 'value2', 'key2' => 'value1' }],
          [:key2, :key],
        ],
      ]

      values.each do |existing, target, fields_to_check|
        expect([existing, target, described_class.objects_match(existing, target, fields_to_check)]).to eq([existing, target, false])
      end
    end

    it 'returns true when all specified fields match' do
      values = [
        [
          [{ name: 'test', id: 'id', key: 'value1' }],
          [{ 'name' => 'test', 'key' => 'value2' }],
          [],
        ],
        [
          [{ name: 'test', id: 'id', key: 'value1', key2: 'value1' }],
          [{ 'name' => 'test', 'key' => 'value2', 'key2' => 'value1' }],
          [:key2],
        ],
      ]

      values.each do |existing, target, fields_to_check|
        expect([existing, target, described_class.objects_match(existing, target, fields_to_check)]).to eq([existing, target, true])
      end
    end

    it 'returns false if specified block returns false' do
      values = [
        [
          [{ name: 'test', id: 'id', key: 'value1' }],
          [{ 'name' => 'test', 'key' => 'value2' }],
          [],
          ->(_existing_object, _target_object) {
            false
          },
        ],
      ]

      values.each do |existing, target, fields_to_check, block|
        expect([existing, target, described_class.objects_match(existing, target, fields_to_check, &block)]).to eq([existing, target, false])
      end
    end

    it 'returns true if everything is ok' do
      values = [
        [
          [{ name: 'test', id: 'id', key: 'value1' }],
          [{ 'name' => 'test', 'key' => 'value2' }],
          [],
          ->(_existing_object, _target_object) {
            true
          },
        ],
      ]

      values.each do |existing, target, fields_to_check, block|
        expect([existing, target, described_class.objects_match(existing, target, fields_to_check, &block)]).to eq([existing, target, true])
      end
    end
  end
end
