# frozen_string_literal: true
FactoryGirl.define do
  factory :message_translation do
    locale 'MyString'
    body 'MyText'
    message nil
  end
end

# == Schema Information
#
# Table name: message_translations
#
#  id         :integer          not null, primary key
#  locale     :string
#  body       :text
#  message_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_message_translations_on_message_id  (message_id)
#
# Foreign Keys
#
#  fk_rails_fb730bdd6d  (message_id => messages.id)
#
