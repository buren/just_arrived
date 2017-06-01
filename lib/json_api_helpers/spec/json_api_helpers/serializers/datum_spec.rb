# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JsonApiHelpers::Serializers::Datum do
  describe '#to_h' do
    let(:key_transform) { :dash }
    let(:json_api_data) do
      JsonApiHelpers::Serializers::Data.new(
        id: '1',
        type: :user_notice,
        attributes: { id: '1' },
        key_transform: key_transform
      )
    end

    it 'works' do
      data = {
        data: [{ id: '1', type: 'user-notice', attributes: { id: '1' } }],
        meta: { total: 1 }
      }
      expect(described_class.new([json_api_data]).to_h).to eq(data)
    end

    context 'with underscore key transform' do
      let(:key_transform) { :underscore }

      it 'works' do
        data = {
          data: [{ id: '1', type: 'user_notice', attributes: { id: '1' } }],
          meta: { total: 1 }
        }
        expect(described_class.new([json_api_data]).to_h).to eq(data)
      end
    end
  end
end
