# frozen_string_literal: true
module Api
  module V1
    module Users
      class FrilansFinansController < BaseController
        after_action :verify_authorized, except: %i(create)

        before_action :set_user

        resource_description do
          short 'API for Frilans Finans users'
          name 'Frilans Finans'
          description ''
          formats [:json]
          api_versions '1.0'
        end

        api :POST, '/users/:user_id/frilans-finans', 'Create new Frilans Finans user'
        # rubocop:disable Metrics/LineLength
        description '
          Creates and returns a new Frilans Finans user.

          __Note__: Account clearning number and account number needs to be present __or__ IBAN and BIC
        '
        # rubocop:enable Metrics/LineLength
        error code: 400, desc: 'Bad request'
        error code: 422, desc: 'Unprocessable entity'
        param :data, Hash, desc: 'Top level key', required: true do
          param :attributes, Hash, desc: 'Frilans Finans payment details', required: true do # rubocop:disable Metrics/LineLength
            param :account_clearing_number, String, desc: 'User account clearing number'
            param :account_number, String, desc: 'User account number'
            param :iban, String, desc: 'IBAN number'
            param :bic, String, desc: 'BIC number'
          end
        end
        example '{}'
        def create
          authorize_create(@user)

          errors = ff_param_errors
          if errors.any?
            render json: errors, status: :unprocessable_entity
            return
          end

          unless frilans_finans_active?
            render json: {}, status: :ok
            return
          end

          if @user.frilans_finans_id.nil?
            complete_params = user_params.merge(ff_user_params)
            document = FrilansFinansApi::User.create(attributes: complete_params)
            @user.frilans_finans_id = document.resource.id
          else
            id = @user.frilans_finans_id!
            # On update Frilans Finans don't want the attribute to be nested under a
            # user key (unlike create)
            FrilansFinansApi::User.update(id: id, attributes: ff_user_params)
          end

          @user.tap do |user|
            user.account_clearing_number = jsonapi_params[:account_clearing_number]
            user.account_number = jsonapi_params[:account_number]

            user.frilans_finans_payment_details = true
            user.save!
          end

          render json: {}, status: :ok
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end

        def user_params
          FrilansFinans::UserWrapper.attributes(@user)
        end

        def ff_user_params
          jsonapi_params.permit(:account_clearing_number, :account_number, :iban, :bic)
        end

        def authorize_create(user)
          raise Pundit::NotAuthorizedError unless policy(user).frilans_finans?
        end

        def ff_param_errors
          errors = validate_non_blank(ff_user_params, :iban, :bic)

          # If one of the two foreign bank fields are filled out return, otherwise we'll
          # assume that the user is gonna add local bank details.
          #
          # The drawback is if no fields at all are submitted only the Swedish
          # bank fields will be returned as blank validation errors
          return foreign_bank_account_errors(errors) if errors.length != 2

          errors = validate_non_blank(
            ff_user_params,
            :account_clearing_number,
            :account_number
          )

          swedish_bank_account_errors(errors)
        end

        def foreign_bank_account_errors(errors)
          # Validate IBAN
          iban_tool = IBANAccount.new(ff_user_params[:iban])
          iban_tool.errors.each do |error|
            message = I18n.t("errors.bank_account.iban.#{error}")
            errors.add(attribute: :iban, detail: message)
          end

          # Validate BIC
          bic_tool = BICTool.new(ff_user_params[:bic])
          bic_tool.errors.each do |error|
            message = I18n.t("errors.bank_account.bic.#{error}")
            errors.add(attribute: :bic, detail: message)
          end
          errors
        end

        def swedish_bank_account_errors(errors)
          full_account = [
            ff_user_params[:account_clearing_number],
            ff_user_params[:account_number]
          ].join

          SwedishBankAccount.new(full_account).errors.map do |error_name|
            # Map what field the error concerns
            pointer = if [:bad_checksum, :unknown_clearing_number].include?(error_name)
                        :account_clearing_number
                      else
                        :account_number
                      end
            message = I18n.t(".errors.bank_account.#{error_name}")
            errors.add(attribute: pointer, detail: message)
          end

          errors
        end

        def frilans_finans_active?
          Rails.configuration.x.frilans_finans
        end

        def validate_non_blank(params_hash, *fields)
          message = I18n.t('errors.messages.blank')
          errors = JsonApiErrors.new
          fields.map do |field|
            errors.add(detail: message, attribute: field) if params_hash[field].blank?
          end
          errors
        end
      end
    end
  end
end
