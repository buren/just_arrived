# frozen_string_literal: true

FactoryGirl.define do
  factory :terms_agreement do
    sequence :version do |n|
      "v#{n}"
    end
    url 'https://example.com'
    association :frilans_finans_term

    factory :terms_agreement_for_docs do
      id 1
      created_at Time.new(2016, 2, 10, 1, 1, 1).utc
      updated_at Time.new(2016, 2, 12, 1, 1, 1).utc
    end
  end
end

# == Schema Information
#
# Table name: terms_agreements
#
#  id                     :integer          not null, primary key
#  version                :string
#  url                    :string(2000)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  frilans_finans_term_id :integer
#
# Indexes
#
#  index_terms_agreements_on_frilans_finans_term_id  (frilans_finans_term_id)
#  index_terms_agreements_on_version                 (version) UNIQUE
#
# Foreign Keys
#
#  fk_rails_d0dcb0c0f5  (frilans_finans_term_id => frilans_finans_terms.id)
#
