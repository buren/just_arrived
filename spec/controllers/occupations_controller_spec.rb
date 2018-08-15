# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::OccupationsController, type: :controller do
  describe 'GET #index' do
    it 'assigns all occupations as @occupations' do
      occupation = FactoryBot.create(:occupation)
      get :index
      expect(assigns(:occupations)).to eq([occupation])
      expect(response.status).to eq(200)
    end

    it 'is able to filter out all root occupations' do
      occupation = FactoryBot.create(:occupation)
      FactoryBot.create(:occupation, parent: occupation)
      get :index, params: { filter: { parent_id: nil } }
      expect(assigns(:occupations)).to eq([occupation])
      expect(response.status).to eq(200)
    end

    it 'is able to filter out children occupations of a specific occupation' do
      occupation1 = FactoryBot.create(:occupation)
      occupation2 = FactoryBot.create(:occupation, parent: occupation1)
      FactoryBot.create(:occupation, parent: occupation2)
      FactoryBot.create(:occupation)

      get :index, params: { filter: { parent_id: occupation1.to_param } }
      expect(assigns(:occupations)).to eq([occupation2])
      expect(response.status).to eq(200)
    end

    it 'allows expired user token' do
      user = FactoryBot.create(:user)
      token = FactoryBot.create(:expired_token, user: user)
      value = token.token
      request.headers['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(value) # rubocop:disable Metrics/LineLength

      get :index
      expect(response.status).to eq(200)
    end
  end

  describe 'GET #show' do
    it 'assigns the requested occupation as @occupations' do
      occupation = FactoryBot.create(:occupation)
      get :show, params: { id: occupation.to_param }
      expect(assigns(:occupation)).to eq(occupation)
      expect(response.status).to eq(200)
    end

    it 'allows expired user token' do
      user = FactoryBot.create(:user)
      token = FactoryBot.create(:expired_token, user: user)
      value = token.token
      request.headers['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(value) # rubocop:disable Metrics/LineLength

      occupation = FactoryBot.create(:occupation)
      get :show, params: { id: occupation.to_param }
      expect(response.status).to eq(200)
    end
  end
end

# == Schema Information
#
# Table name: occupations
#
#  id          :bigint(8)        not null, primary key
#  name        :string
#  ancestry    :string
#  language_id :bigint(8)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_occupations_on_ancestry     (ancestry)
#  index_occupations_on_language_id  (language_id)
#
# Foreign Keys
#
#  fk_rails_...  (language_id => languages.id)
#
