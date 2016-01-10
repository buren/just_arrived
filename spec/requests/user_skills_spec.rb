require 'rails_helper'

RSpec.describe 'UserSkills', type: :request do
  describe 'GET /users/1/skills' do
    it 'works!' do
      user = FactoryGirl.create(:user)
      get api_v1_user_skills_path(user_id: user.to_param)
      expect(response).to have_http_status(200)
    end
  end
end
