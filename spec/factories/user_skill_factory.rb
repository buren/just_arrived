# frozen_string_literal: true
FactoryGirl.define do
  factory :user_skill do
    association :skill
    association :user

    factory :user_skill_for_docs do
      id 1
      created_at Time.new(2016, 02, 10, 1, 1, 1).utc
      updated_at Time.new(2016, 02, 12, 1, 1, 1).utc
    end
  end
end

# == Schema Information
#
# Table name: user_skills
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  skill_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_user_skills_on_skill_id              (skill_id)
#  index_user_skills_on_skill_id_and_user_id  (skill_id,user_id) UNIQUE
#  index_user_skills_on_user_id               (user_id)
#  index_user_skills_on_user_id_and_skill_id  (user_id,skill_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_59acb6e327  (skill_id => skills.id)
#  fk_rails_fe61b6a893  (user_id => users.id)
#
