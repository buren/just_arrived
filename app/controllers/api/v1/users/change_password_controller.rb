# frozen_string_literal: true
module Api
  module V1
    module Users
      class ChangePasswordController < BaseController
        after_action :verify_authorized, only: []

        before_action :set_user

        api :POST, '/users/change_password/', 'Change password'
        description 'Change password for user, use one time token if the user is not logged in' # rubocop:disable Metrics/LineLength
        error code: 404, desc: 'Not found'
        error code: 422, desc: 'Unprocessable entity'
        param :data, Hash, desc: 'Top level key', required: true do
          param :attributes, Hash, desc: 'Reset password attributes', required: true do
            param :password, String, desc: 'New password', required: true
            param :one_time_token, String, desc: 'One time token'
          end
        end
        example '# Response example
{}
'
        def create
          if User.valid_password?(user_params[:password])
            @user.update!(user_params)
            ChangedPasswordNotifier.call(user: @user)

            render json: {}
          else
            respond_with_password_error
          end
        end

        private

        def set_user
          @user = if logged_in?
                    current_user
                  else
                    token = jsonapi_params[:one_time_token]
                    token_user = User.find_by_one_time_token(token)
                    if token_user.nil?
                      render json: {}, status: :not_found
                      return false
                    end
                    token_user
                  end
        end

        def user_params
          jsonapi_params.permit(:password)
        end

        def respond_with_password_error
          min_length = User::MIN_PASSWORD_LENGTH
          message = I18n.t('errors.user.password_length', count: min_length)
          response_json = {
            errors: [{ status: 422, detail: message }]
          }
          render json: response_json, status: :unprocessable_entity
        end
      end
    end
  end
end
