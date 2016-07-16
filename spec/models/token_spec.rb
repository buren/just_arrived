# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Token, type: :model do
  describe '#default_expires_at' do
    it 'sets default expires at if unset' do
      token = described_class.new
      expect(token.expires_at).to be_nil

      Timecop.freeze(Time.zone.now) do
        expected_date = described_class::DEFAULT_EXPIRE_IN_DAYS.days.from_now
        token.validate

        expect(token.expires_at).to eq(expected_date)
      end
    end

    it 'leaves expires at if set' do
      token = described_class.new
      expires_at = 1.day.from_now
      token.expires_at = expires_at
      token.validate
      expect(token.expires_at).to eq(expires_at)
    end
  end

  describe '#regenerate_token' do
    it 'regenerates token' do
      token = described_class.create
      first_token = token.regenerate_token
      expect(token.token.length).to eq(96)

      token.regenerate_token

      expect(token.token).not_to eq(first_token)
      expect(token.token.length).to eq(96)
    end

    it 'leaves expires at if set' do
      token = described_class.new
      expires_at = 1.day.from_now
      token.expires_at = expires_at
      token.validate
      expect(token.expires_at).to eq(expires_at)
    end
  end
end

# == Schema Information
#
# Table name: tokens
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  token      :string
#  expires_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_tokens_on_token    (token)
#  index_tokens_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_ac8a5d0441  (user_id => users.id)
#
