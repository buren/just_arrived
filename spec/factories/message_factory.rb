# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    body 'Message content.'
    association :author, factory: :user
    association :language
    association :chat

    factory :message_for_docs do
      id 1
      created_at Time.new(2016, 2, 10, 1, 1, 1).utc
      updated_at Time.new(2016, 2, 12, 1, 1, 1).utc
    end
  end
end

# == Schema Information
#
# Table name: messages
#
#  id          :integer          not null, primary key
#  chat_id     :integer
#  author_id   :integer
#  integer     :integer
#  language_id :integer
#  body        :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_messages_on_chat_id      (chat_id)
#  index_messages_on_language_id  (language_id)
#
# Foreign Keys
#
#  fk_rails_...           (chat_id => chats.id)
#  fk_rails_...           (language_id => languages.id)
#  messages_author_id_fk  (author_id => users.id)
#
