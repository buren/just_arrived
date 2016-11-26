# frozen_string_literal: true
module Api
  module V1
    class BaseController < ::Api::BaseController
      resource_description do
        api_version '1.0'
        app_info <<-DOCDESCRIPTION
          # JustMatch API - v1.0 (beta) <a href="http://jsonapi.org/"><svg xmlns="http://www.w3.org/2000/svg" style="font-weight:normal;" width="90" height="20"><linearGradient id="b" x2="0" y2="100%"><stop offset="0" stop-color="#bbb" stop-opacity=".1"/><stop offset="1" stop-opacity=".1"/></linearGradient><mask id="a"><rect width="90" height="20" rx="3" fill="#fff"/></mask><g mask="url(#a)"><path fill="#555" d="M0 0h63v20H0z"/><path fill="#9f9f9f" d="M63 0h27v20H63z"/><path fill="url(#b)" d="M0 0h90v20H0z"/></g><g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11"><text x="31.5" y="15" fill="#010101" fill-opacity=".3">JSON API</text><text x="31.5" y="14">JSON API</text><text x="75.5" y="15" fill="#010101" fill-opacity=".3">1.0</text><text x="75.5" y="14">1.0</text></g></svg></a>

          ---

          The API follows the [JSON API 1.0](http://jsonapi.org) specification.

          ---

          ### Headers

          __Content-Type__

          The correct Content-Type is:

          `Content-Type: application/vnd.api+json`

          Please note that the correct Content-Type isn't standard. See the specification at [jsosnapi.org/format](http://jsonapi.org/format/#content-negotiation-clients).

          __Locale__

          `X-API-LOCALE: en` is used to specify current locale, valid locales are #{I18n.available_locales.map { |locale| "`#{locale}`" }.join(', ')}

          __Authorization__

          `Authorization: Token token=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`

          __Promo code (not always active)__

          `X-API-PROMO-CODE: promocode` is used to specify the promo code, logged in users and logged in attemps are exempt.

          ---

          ### Example job scenario

          Action | Request |
          ------------------------------------------------------------------------------------------|:-------------------------------------------------------------|
          1. Owner creates job                                                                      | `POST /api/v1/jobs/`                                         |
          2. User can apply to a job by creating a job user                                         | `POST /api/v1/jobs/:job_id/users/`                           |
          3. Owner can accept a user                                                                | `POST /api/v1/jobs/:job_id/users/:job_user_id/acceptances`   |
          4. User confirms that they will perform                                                   | `POST /api/v1/jobs/:job_id/users/:job_user_id/confirmations` |
          5. Check if user has added bank account details (frilans_finans_payment_details: `true`)  | `GET  /api/v1/users/:id`                                      |
          5.1 If `false` then add bank account details                                              | `POST /api/v1/users/:user_id/frilans-finans`
          6. Owner creates invoice                                                                  | `POST /api/v1/jobs/:job_id/users/:job_user_id/invoices`      |
          7. (optional) User confirms that they've performed the job                                | `POST /api/v1/jobs/:job_id/users/:job_user_id/performed`     |

          ---

          ### Examples

          __Jobs__

          Get a list of available jobs

              #{Doxxer.curl_for(name: 'jobs')}

          Get a single job

              #{Doxxer.curl_for(name: 'jobs', id: 1)}

          __Skills__

          Get a list of skills

              #{Doxxer.curl_for(name: 'skills')}

          Get a single skill

              #{Doxxer.curl_for(name: 'skills', id: 1)}

          ### Locale

          Set the locale

              #{Doxxer.curl_for(name: 'users', id: 1, locale: true, join_with: " \\
                     ")}

          ### Authentication

          Pass the authorization token as a HTTP header

              #{Doxxer.curl_for(name: 'users', id: 1, auth: true, join_with: " \\
                     ")}

          ## Errors

          ### 401 - Login Required

              #{JSON.parse(Doxxer.read_example_file(:login_required)).to_json}

          ### 401 - Token Expired

              #{JSON.parse(Doxxer.read_example_file(:token_expired)).to_json}

          ### 403 - Invalid Credentials

              #{JSON.parse(Doxxer.read_example_file(:invalid_credentials)).to_json}

          ### 404 - Not Found

              #{JSON.parse(Doxxer.read_example_file(:not_found)).to_json}

        DOCDESCRIPTION
        api_base_url '/api/v1'
      end

      ExpiredTokenError = Class.new(ArgumentError)

      before_action :authenticate_user_token!
      before_action :require_promo_code
      before_action :set_locale

      ALLOWED_INCLUDES = [].freeze

      # Needed for #authenticate_with_http_token
      include ActionController::HttpAuthentication::Token::ControllerMethods

      after_action :verify_authorized

      rescue_from Pundit::NotAuthorizedError, with: :user_forbidden
      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
      rescue_from ExpiredTokenError, with: :expired_token

      def jsonapi_params
        @_deserialized_params ||= JsonApiDeserializer.parse(params)
      end

      def include_params
        @_include_params ||= JsonApiIncludeParams.new(params[:include])
      end

      def fields_params
        @_fields_params ||= JsonApiFieldsParams.new(params[:fields])
      end

      def included_resources
        @_included_resources ||= include_params.permit(self.class::ALLOWED_INCLUDES)
      end

      def included_resource?(resource_name)
        included_resources.include?(resource_name.to_s)
      end

      def require_promo_code
        return if logged_in?

        promo_code = Rails.configuration.x.promo_code
        return if promo_code.nil? || promo_code == {} # Rails config can return nil & {}
        return if promo_code == api_promo_code_header

        status = 401 # unauthorized
        errors = PromoCodeOrLoginRequired.add(JsonApiErrors.new)
        render json: errors, status: status
      end

      protected

      def api_render_errors(model)
        serialized_error = { errors: JsonApiErrorSerializer.serialize(model) }
        render json: serialized_error, status: :unprocessable_entity
      end

      def api_render(model_or_model_array, status: :ok, total: nil, meta: {})
        model = model_or_model_array
        meta[:total] = total if total

        meta[:current_page] = model.current_page if model.respond_to?(:current_page)
        meta[:total_pages] = model.total_pages if model.respond_to?(:total_pages)

        serialized_model = JsonApiSerializer.serialize(
          model,
          key_transform: key_transform_header,
          included: included_resources,
          fields: fields_params.to_h,
          current_user: current_user,
          meta: meta,
          request: request
        )

        render json: serialized_model, status: status
      end

      def record_not_found
        errors = NotFound.add(JsonApiErrors.new)

        render json: errors, status: :not_found
      end

      def require_user
        return if logged_in?

        errors = LoginRequired.add(JsonApiErrors.new)
        render json: errors, status: :unauthorized
      end

      def user_forbidden
        status = nil
        errors = JsonApiErrors.new

        if logged_in?
          status = 403 # forbidden
          InvalidCredentials.add(errors)
        else
          status = 401 # unauthorized
          LoginRequired.add(errors)
        end

        render json: errors, status: status
      end

      def expired_token
        errors = TokenExpired.add(JsonApiErrors.new)

        status = 401 # unauthorized
        render json: errors.to_json, status: status
      end

      def current_user
        @_current_user ||= User.new
      end

      def login_user(user)
        @_current_user = user
      end

      def not_logged_in?
        !logged_in?
      end

      def logged_in?
        current_user.persisted?
      end

      def set_locale
        locale_header = api_locale_header
        if locale_header.nil?
          I18n.locale = current_user.locale
          return
        end

        # Only allow available locales
        I18n.available_locales.map(&:to_s).each do |locale|
          I18n.locale = locale if locale == locale_header
        end
      end

      def api_locale_header
        request.headers['X-API-LOCALE']
      end

      def api_promo_code_header
        request.headers['X-API-PROMO-CODE']
      end

      def key_transform_header
        case request.headers['X-API-KEY-TRANSFORM']
        when 'underscore' then :underscore
        else
          'dash'
        end
      end

      def act_as_user_header
        request.headers['X-API-ACT-AS-USER']
      end

      private

      def authenticate_user_token!
        authenticate_with_http_token do |auth_token, _options|

          token = Token.includes(:user).find_by(token: auth_token)
          return if token.nil?
          return raise ExpiredTokenError if token.expired?

          user = token.user

          if user.admin? && !act_as_user_header.blank?
            user = User.find(act_as_user_header)
          end

          return login_user(user)
        end
      end
    end
  end
end
