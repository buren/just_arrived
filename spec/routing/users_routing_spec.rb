# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      path = '/api/v1/users'
      expect(get: path).to route_to('api/v1/users#index')
    end

    it 'routes to #show' do
      path = '/api/v1/users/1'
      expect(get: path).to route_to('api/v1/users#show', user_id: '1')
    end

    it 'routes to #create' do
      path = '/api/v1/users'
      expect(post: path).to route_to('api/v1/users#create')
    end

    it 'routes to #update via PUT' do
      path = '/api/v1/users/1'
      expect(put: path).to route_to('api/v1/users#update', user_id: '1')
    end

    it 'routes to #update via PATCH' do
      path = '/api/v1/users/1'
      expect(patch: path).to route_to('api/v1/users#update', user_id: '1')
    end

    it 'routes to #images' do
      path = '/api/v1/users/images'
      route_path = 'api/v1/users#images'
      expect(post: path).to route_to(route_path)
    end

    it 'routes to #matching_jobs' do
      path = '/api/v1/users/1/matching-jobs'
      expect(get: path).to route_to('api/v1/users#matching_jobs', user_id: '1')
    end

    it 'routes to #available_notifications' do
      path = '/api/v1/users/1/available-notifications'
      expect(get: path).to route_to('api/v1/users#available_notifications', user_id: '1')
    end

    it 'routes to #notifications' do
      path = '/api/v1/users/notifications'
      expect(get: path).to route_to('api/v1/users#notifications')
    end

    it 'routes to #statuses' do
      path = '/api/v1/users/statuses'
      expect(get: path).to route_to('api/v1/users#statuses')
    end

    it 'routes to #genders' do
      path = '/api/v1/users/genders'
      expect(get: path).to route_to('api/v1/users#genders')
    end

    it 'routes to #missing_traits' do
      path = '/api/v1/users/1/missing-traits'
      expect(get: path).to route_to('api/v1/users#missing_traits', user_id: '1')
    end
  end
end

# == Schema Information
#
# Table name: users
#
#  id                               :integer          not null, primary key
#  email                            :string
#  phone                            :string
#  description                      :text
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  latitude                         :float
#  longitude                        :float
#  language_id                      :integer
#  anonymized                       :boolean          default(FALSE)
#  password_hash                    :string
#  password_salt                    :string
#  admin                            :boolean          default(FALSE)
#  street                           :string
#  zip                              :string
#  zip_latitude                     :float
#  zip_longitude                    :float
#  first_name                       :string
#  last_name                        :string
#  ssn                              :string
#  company_id                       :integer
#  banned                           :boolean          default(FALSE)
#  job_experience                   :text
#  education                        :text
#  one_time_token                   :string
#  one_time_token_expires_at        :datetime
#  ignored_notifications_mask       :integer
#  frilans_finans_id                :integer
#  frilans_finans_payment_details   :boolean          default(FALSE)
#  competence_text                  :text
#  current_status                   :integer
#  at_und                           :integer
#  arrived_at                       :date
#  country_of_origin                :string
#  managed                          :boolean          default(FALSE)
#  account_clearing_number          :string
#  account_number                   :string
#  verified                         :boolean          default(FALSE)
#  skype_username                   :string
#  interview_comment                :text
#  next_of_kin_name                 :string
#  next_of_kin_phone                :string
#  arbetsformedlingen_registered_at :date
#  city                             :string
#  interviewed_by_user_id           :integer
#  interviewed_at                   :datetime
#  just_arrived_staffing            :boolean          default(FALSE)
#  super_admin                      :boolean          default(FALSE)
#  gender                           :integer
#  presentation_profile             :text
#  presentation_personality         :text
#  presentation_availability        :text
#  system_language_id               :integer
#  linkedin_url                     :string
#  facebook_url                     :string
#  has_welcome_app_account          :boolean          default(FALSE)
#  welcome_app_last_checked_at      :datetime
#  public_profile                   :boolean          default(FALSE)
#
# Indexes
#
#  index_users_on_company_id          (company_id)
#  index_users_on_email               (email) UNIQUE
#  index_users_on_frilans_finans_id   (frilans_finans_id) UNIQUE
#  index_users_on_language_id         (language_id)
#  index_users_on_one_time_token      (one_time_token) UNIQUE
#  index_users_on_system_language_id  (system_language_id)
#
# Foreign Keys
#
#  fk_rails_...                     (company_id => companies.id)
#  fk_rails_...                     (language_id => languages.id)
#  users_interviewed_by_user_id_fk  (interviewed_by_user_id => users.id)
#  users_system_language_id_fk      (system_language_id => languages.id)
#
