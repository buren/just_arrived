# frozen_string_literal: true
require 'rails_helper'

RSpec.describe UserLanguage, type: :model do
end

# == Schema Information
#
# Table name: user_languages
#
#  id          :integer          not null, primary key
#  language_id :integer
#  user_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_user_languages_on_language_id  (language_id)
#  index_user_languages_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_0be39eaff3  (language_id => languages.id)
#  fk_rails_db4f7502c2  (user_id => users.id)
#
