# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Language, type: :model do
end

# == Schema Information
#
# Table name: languages
#
#  id         :integer          not null, primary key
#  lang_code  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_languages_on_lang_code  (lang_code) UNIQUE
#
