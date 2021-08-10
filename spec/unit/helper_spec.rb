require 'puppet_x/ionoscloud/helper'

describe PuppetX::IonoscloudX::Helper do
  describe '#sync_objects' do
    it 'should call nothing and return [] if target is nil' do
      existing = []
      target = nil
      aux_args = []

      expect(PuppetX::IonoscloudX::Helper).not_to receive(:wait_request)

      ret = nil
      expect { ret = PuppetX::IonoscloudX::Helper.sync_objects(existing, target, aux_args, :invalid_method, :invalid_method, :invalid_method) }.not_to raise_error(Exception)
      expect(ret).to eq([])
    end

    it 'should call nothing when existing and target are []' do
      existing = []
      target = []
      aux_args = []

      expect(PuppetX::IonoscloudX::Helper).not_to receive(:wait_request)

      ret = nil
      expect { ret = PuppetX::IonoscloudX::Helper.sync_objects(existing, target, aux_args, :invalid_method, :invalid_method, :invalid_method) }.not_to raise_error(Exception)
      expect(ret).to eq([])
    end

    it 'should call create' do
      existing = []
      target = [{ 'name' => 'test' , 'extra' => 'test_extra'}]
      aux_args = ['test1', 'test2']

      expect(PuppetX::IonoscloudX::Helper).not_to receive(:wait_request)
      expect(PuppetX::IonoscloudX::Helper).to receive(:create_empty).once do |*args|
        expect(args).to eq(aux_args + target)
        ['id', 'test']
      end

      ret = nil
      expect { ret = PuppetX::IonoscloudX::Helper.sync_objects(existing, target, aux_args, :invalid_method, :create_empty, :invalid_method) }.not_to raise_error(Exception)
      expect(ret).to eq(['test'])
    end

    it 'should call update' do
      existing = [{ id: 'id', name: 'test' , extra: 'test_extra_old'}]
      target = [{ 'name' => 'test' , 'extra' => 'test_extra'}]
      aux_args = ['test1', 'test2']

      expect(PuppetX::IonoscloudX::Helper).not_to receive(:wait_request)
      expect(PuppetX::IonoscloudX::Helper).to receive(:update_empty).once do |*args|
        expect(args).to eq(aux_args + ['id'] + existing + target)
        ['test']
      end

      ret = nil
      expect { ret = PuppetX::IonoscloudX::Helper.sync_objects(existing, target, aux_args, :update_empty, :invalid_method, :invalid_method) }.not_to raise_error(Exception)
      expect(ret).to eq(['test'])
    end

    it 'should call delete' do
      existing = [{ id: 'id', name: 'test' , extra: 'test_extra_old'}]
      target = []
      aux_args = ['test1', 'test2']

      expect(PuppetX::IonoscloudX::Helper).not_to receive(:wait_request)
      expect(PuppetX::IonoscloudX::Helper).to receive(:delete_empty).once do |*args|
        expect(args).to eq(aux_args + ['id'])
        'test'
      end

      ret = nil
      expect { ret = PuppetX::IonoscloudX::Helper.sync_objects(existing, target, aux_args, :invalid_method, :invalid_method, :delete_empty) }.not_to raise_error(Exception)
      expect(ret).to eq(['test'])
    end

    it 'should call all methods' do
      existing = [{ id: 'id', name: 'test' , extra: 'test_extra_old'}, { id: 'id2', name: 'test2' , extra: 'test_extra_old2'}]
      target = [{ 'name' => 'test2' , 'extra' => 'test_extra4'}, { 'name' => 'test3' , 'extra' => 'test_extra3'}]
      aux_args = ['test_id1', 'test_id2']

      expect(PuppetX::IonoscloudX::Helper).not_to receive(:wait_request)
      expect(PuppetX::IonoscloudX::Helper).to receive(:create_empty).once do |*args|
        expect(args).to eq(aux_args + [target[1]])
        ['create_id', 'create_test']
      end
      expect(PuppetX::IonoscloudX::Helper).to receive(:update_empty).once do |*args|
        expect(args).to eq(aux_args + [existing[1][:id]] + [existing[1]] + [target[0]])
        ['update_test']
      end
      expect(PuppetX::IonoscloudX::Helper).to receive(:delete_empty).once do |*args|
        expect(args).to eq(aux_args + [existing[0][:id]])
        'delete_test'
      end

      ret = nil
      expect { ret = PuppetX::IonoscloudX::Helper.sync_objects(existing, target, aux_args, :update_empty, :create_empty, :delete_empty) }.not_to raise_error(Exception)
      expect(ret).to eq(['update_test', 'create_test', 'delete_test'])
    end


    it 'should call all methods using custom field' do
      existing = [{ id: 'id', custom_name: 'test' , extra: 'test_extra_old'}, { id: 'id2', custom_name: 'test2' , extra: 'test_extra_old2'}]
      target = [{ 'custom_name' => 'test2' , 'extra' => 'test_extra4'}, { 'custom_name' => 'test3' , 'extra' => 'test_extra3'}]
      aux_args = ['test_id1', 'test_id2']

      expect(PuppetX::IonoscloudX::Helper).not_to receive(:wait_request)
      expect(PuppetX::IonoscloudX::Helper).to receive(:create_empty).once do |*args|
        expect(args).to eq(aux_args + [target[1]])
        ['create_id', 'create_test']
      end
      expect(PuppetX::IonoscloudX::Helper).to receive(:update_empty).once do |*args|
        expect(args).to eq(aux_args + [existing[1][:id]] + [existing[1]] + [target[0]])
        ['update_test']
      end
      expect(PuppetX::IonoscloudX::Helper).to receive(:delete_empty).once do |*args|
        expect(args).to eq(aux_args + [existing[0][:id]])
        'delete_test'
      end
      ret = nil
      expect { ret = PuppetX::IonoscloudX::Helper.sync_objects(existing, target, aux_args, :update_empty, :create_empty, :delete_empty, false, :custom_name) }.not_to raise_error(Exception)
      expect(ret).to eq(['update_test', 'create_test', 'delete_test'])
    end
  end

  describe '#compare_objects' do
    it 'should return false when existing and target are different' do
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
        expect([existing, target, PuppetX::IonoscloudX::Helper.compare_objects(existing, target)]).to eq([existing, target, false])
      end
    end

    it 'should return true when existing and target are the same' do
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
        expect([existing, target, PuppetX::IonoscloudX::Helper.compare_objects(existing, target)]).to eq([existing, target, true])
      end
    end
  end

  describe '#objects_match' do
    it 'should return true when target_objects is nil' do
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
        expect([existing, target, PuppetX::IonoscloudX::Helper.objects_match(existing, target, fields_to_check)]).to eq([existing, target, true])
      end
    end

    it 'should return false when existing_objects and target_objects have different lengths' do
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
        expect([existing, target, PuppetX::IonoscloudX::Helper.objects_match(existing, target, fields_to_check)]).to eq([existing, target, false])
      end
    end

    it 'should return false when an object from target_objects does not exist in existing_objects' do
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
        expect([existing, target, PuppetX::IonoscloudX::Helper.objects_match(existing, target, fields_to_check)]).to eq([existing, target, false])
      end
    end
  end
end
