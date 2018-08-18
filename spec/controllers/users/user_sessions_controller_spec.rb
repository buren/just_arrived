# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Users::UserSessionsController, type: :controller do
  let(:email) { 'someone@example.com' }
  let(:password) { '12345678' }
  let(:valid_attributes) do
    {
      data: {
        attributes: {
          email_or_phone: email,
          password: password
        }
      }
    }
  end

  let(:invalid_attributes) do
    {}
  end

  describe 'POST #create' do
    context 'valid user' do
      context 'with email given' do
        before(:each) do
          attrs = { email: email, password: password }
          FactoryBot.create(:user, attrs)
        end

        it 'should work with uppercase email address' do
          attributes = valid_attributes.dup
          attributes[:data][:attributes][:email_or_phone] = email.upcase

          post :create, params: attributes
          expect(response.status).to eq(201)
        end

        it 'should work with extra spaces in email address' do
          attributes = valid_attributes.dup
          attributes[:data][:attributes][:email_or_phone] = "  #{email}  "

          post :create, params: attributes
          expect(response.status).to eq(201)
        end

        it 'should return success status' do
          post :create, params: valid_attributes
          expect(response.status).to eq(201)
        end

        it 'should return JSON with token key' do
          post :create, params: valid_attributes
          json = JSON.parse(response.body)
          jsonapi_params = JsonApiDeserializer.parse(json)
          expected = SecureGenerator::DEFAULT_TOKEN_LENGTH
          expect(jsonapi_params['auth_token'].length).to eq(expected)
        end

        it 'should return JSON with user id' do
          post :create, params: valid_attributes
          json = JSON.parse(response.body)
          jsonapi_params = JsonApiDeserializer.parse(json)
          expect(jsonapi_params['user_id']).not_to be_nil
        end

        it 'allows expired user token' do
          user = FactoryBot.create(:user)
          token = FactoryBot.create(:expired_token, user: user)
          value = token.token
          request.headers['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(value) # rubocop:disable Metrics/LineLength

          post :create, params: valid_attributes
          expect(response.status).to eq(201)
        end
      end

      context 'with phone given' do
        it 'should return success status' do
          password = '12345678'
          user = FactoryBot.create(:user, password: password)
          valid_attributes = {
            data: {
              attributes: {
                email_or_phone: user.phone,
                password: password
              }
            }
          }

          post :create, params: valid_attributes
          expect(response.status).to eq(201)
        end
      end
    end

    context 'invalid user' do
      it 'should return forbidden status' do
        post :create, params: valid_attributes
        expect(response.status).to eq(422)
      end

      it 'returns explaination' do
        post :create, params: valid_attributes
        message = I18n.t('errors.user_session.wrong_email_or_phone_or_password')
        json = JSON.parse(response.body)
        first_detail = json['errors'].first['detail']
        last_detail = json['errors'].last['detail']

        # The message for both password & email should be the same
        expect(first_detail).to eq(message)
        expect(last_detail).to eq(message)
      end
    end

    context 'banned user' do
      before(:each) do
        attrs = { email: 'someone@example.com', password: '12345678', banned: true }
        FactoryBot.create(:user, attrs)
      end

      it 'returns forbidden status' do
        post :create, params: valid_attributes
        expect(response.status).to eq(403)
      end

      it 'allows expired user token' do
        user = FactoryBot.create(:user)
        token = FactoryBot.create(:expired_token, user: user)
        value = token.token
        request.headers['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(value) # rubocop:disable Metrics/LineLength

        post :create, params: valid_attributes
        expect(response.status).to eq(403)
      end

      it 'returns explaination' do
        post :create, params: valid_attributes
        json = JSON.parse(response.body)
        message = 'an admin has banned'
        detail = json['errors'].first['detail']
        expect(detail.starts_with?(message)).to eq(true)
      end
    end

    context 'login with one time token' do
      let(:user) do
        u = FactoryBot.create(:user)
        u.generate_one_time_token
        u.save!
        u
      end
      let(:valid_attributes) do
        {
          data: {
            attributes: {
              one_time_token: user.one_time_token
            }
          }
        }
      end

      it 'returns valid response' do
        post :create, params: valid_attributes

        json = JSON.parse(response.body)
        jsonapi_params = JsonApiDeserializer.parse(json)

        expect(jsonapi_params['auth_token']).to eq(user.auth_token)
        expect(response.status).to eq(201)
      end
    end
  end

  describe 'DELETE #token' do
    context 'valid user' do
      it 'should return success status' do
        user = FactoryBot.create(:user_with_tokens, email: 'someone@example.com')
        token = user.auth_token
        delete :destroy, params: { id: token }
        expect(response.status).to eq(204)
      end

      it 'destroys users auth token' do
        user = FactoryBot.create(:user, email: 'someone@example.com')
        token = user.create_auth_token
        auth_token = token.token
        expect(user.auth_tokens.first.expired?).to eq(false)
        delete :destroy, params: { id: auth_token }
        user.reload
        expect(user.auth_tokens.first.expired?).to eq(true)
      end
    end

    context 'no such user auth_token' do
      it 'should return 404 not found' do
        FactoryBot.create(:user_with_tokens, email: 'someone@example.com')
        delete :destroy, params: { id: 'dasds' }
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'POST #magic_link' do
    context 'valid phone' do
      let(:valid_params) do
        FactoryBot.create(:user_with_tokens, phone: '073 500 0000')
        {
          data: {
            attributes: {
              email_or_phone: '073-500 0000'
            }
          }
        }
      end

      it 'sends notification' do
        allow(MagicLoginLinkNotifier).to receive(:call)
        post :magic_link, params: valid_params
        expect(MagicLoginLinkNotifier).to have_received(:call).once
      end

      it 'returns 202 accepted status' do
        allow(AppSecrets).to receive(:twilio_account_sid).and_return('notsosecret')
        allow(AppSecrets).to receive(:twilio_auth_token).and_return('notsosecret')

        post :magic_link, params: valid_params
        expect(response.status).to eq(202)
      end
    end

    context 'invalid phone' do
      it 'returns 202 accepted status' do
        post :magic_link
        expect(response.status).to eq(202)
      end
    end
  end
end
