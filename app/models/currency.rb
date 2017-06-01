# frozen_string_literal: true

class Currency < ApplicationRecord
  validates :frilans_finans_id, uniqueness: true
  validates :currency_code, presence: true

  def self.default_currency
    find_by(currency_code: 'SEK')
  end
end

# == Schema Information
#
# Table name: currencies
#
#  id                :integer          not null, primary key
#  currency_code     :string
#  frilans_finans_id :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_currencies_on_frilans_finans_id  (frilans_finans_id) UNIQUE
#
