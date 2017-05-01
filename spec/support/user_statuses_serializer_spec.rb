# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserStatusesSerializer do
  describe '#serializeble_resource' do
    subject { described_class.serializeble_resource(key_transform: :dash).to_h }

    it 'returns serialized statues' do
      data = subject[:data].first
      expect(data[:id]).to eq(:asylum_seeker)

      en_name = I18n.t('user.statuses.asylum_seeker', locale: :en)
      ar_name = I18n.t('user.statuses.asylum_seeker', locale: :ar)

      expect(data[:attributes][:name]).to eq(en_name)
      expect(data[:attributes][:'translated-text'][:name]).to eq(ar_name)
    end
  end
end
