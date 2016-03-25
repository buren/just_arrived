# frozen_string_literal: true
module Api
  module V1
    module Users
      class UserLanguagesController < BaseController
        before_action :set_user
        before_action :set_language, only: [:show, :destroy]
        before_action :set_user_language, only: [:show, :destroy]

        resource_description do
          short 'API for managing user languages'
          name 'User languages'
          description '
            User languages is the relationship between a user and a language.
          '
          formats [:json]
          api_versions '1.0'
        end

        api :GET, '/users/:user_id/languages', 'List user languages'
        description 'Returns a list of user languages.'
        example Doxxer.read_example(UserLanguage, plural: true)
        def index
          authorize(UserLanguage)

          user_languages_index = Index::UserLanguagesIndex.new(self)
          @user_languages = user_languages_index.user_languages(@user.user_languages)

          api_render(@user_languages, included: user_languages_index.included)
        end

        api :GET, '/users/:user_id/languages/:id', 'Show language'
        description 'Return language.'
        error code: 404, desc: 'Not found'
        example Doxxer.read_example(UserLanguage)
        def show
          authorize(UserLanguage)

          api_render(@user_language, included: 'language')
        end

        api :POST, '/users/:user_id/languages/', 'Create new user language'
        description 'Creates and returns new user language.'
        error code: 400, desc: 'Bad request'
        error code: 404, desc: 'Not found'
        error code: 422, desc: 'Unprocessable entity'
        error code: 401, desc: 'Unauthorized'
        param :data, Hash, desc: 'Top level key', required: true do
          param :attributes, Hash, desc: 'User language attributes', required: true do
            param :id, Integer, desc: 'Language id', required: true
          end
        end
        example Doxxer.read_example(UserLanguage)
        def create
          @user_language = UserLanguage.new
          @user_language.user = @user

          authorize(@user_language)

          @user_language.language = Language.find_by(id: user_language_params[:id])

          if @user_language.save
            api_render(@user_language, included: 'language', status: :created)
          else
            respond_with_errors(@user_language)
          end
        end

        api :DELETE, '/users/:user_id/languages/:id', 'Delete user language'
        description 'Deletes user language.'
        error code: 401, desc: 'Unauthorized'
        error code: 404, desc: 'Not found'
        def destroy
          authorize(@user_language)

          @user_language.destroy

          head :no_content
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end

        def set_language
          @language = @user.languages.find(params[:id])
        end

        def set_user_language
          @user_language = @user.user_languages.find_by!(language: @language)
        end

        def user_language_params
          jsonapi_params.permit(:id)
        end

        def pundit_user
          UserLanguagePolicy::Context.new(current_user, @user)
        end
      end
    end
  end
end
