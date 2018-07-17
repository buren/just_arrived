# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GuideSectionArticleTranslation, type: :model do
end

# == Schema Information
#
# Table name: guide_section_article_translations
#
#  id                       :bigint(8)        not null, primary key
#  language_id              :bigint(8)
#  guide_section_article_id :integer
#  locale                   :string
#  title                    :string
#  slug                     :string
#  short_description        :string
#  body                     :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_guide_section_article_translations_on_language_id  (language_id)
#
# Foreign Keys
#
#  fk_rails_...  (guide_section_article_id => guide_section_articles.id)
#  fk_rails_...  (language_id => languages.id)
#
