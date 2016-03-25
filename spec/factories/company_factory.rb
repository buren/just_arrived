# frozen_string_literal: true
FactoryGirl.define do
  factory :company do
    name 'A company'
    sequence :cin do |n|
      num_length = case n
                   when 0...10 then 9
                   when 10...100 then 8
                   else 7
                   end
      "#{Faker::Number.number(num_length)}#{n}"
    end

    factory :company_for_docs do
      id 1
      cin '5560360793'
      created_at Time.new(2016, 02, 10, 1, 1, 1).utc
      updated_at Time.new(2016, 02, 12, 1, 1, 1).utc
    end
  end
end

# == Schema Information
#
# Table name: companies
#
#  id         :integer          not null, primary key
#  name       :string
#  cin        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_companies_on_cin  (cin) UNIQUE
#
