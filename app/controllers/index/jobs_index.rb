# frozen_string_literal: true

module Index
  class JobsIndex < BaseIndex
    FILTER_MATCH_TYPES = {
      open_for_applications: :fake_attribute,
      filled: :fake_attribute,
      name: { translated: :contains },
      description: { translated: :contains }
    }.freeze
    TRANSFORMABLE_FILTERS = TRANSFORMABLE_FILTERS.merge(job_date: :date_range).freeze
    ALLOWED_FILTERS = %i(
      id name description hours created_at job_date filled featured cancelled
      staffing_company_id direct_recruitment_job open_for_applications job_user.user_id
    ).freeze
    SORTABLE_FIELDS = %i(
      hours job_date name filled featured created_at updated_at
      direct_recruitment_job staffing_company_id
    ).freeze

    def jobs(scope = Job)
      @jobs ||= begin
        include_scopes = %i(
          language company category hourly_pay job_skills job_languages
        )

        include_scopes << user_include_scopes(user_key: :owner)

        scope = filter_job_user_jobs(scope, filter_params[:'job_user.user_id'])
        scope = filter_open_for_application(scope, filter_params[:open_for_applications])
        scope = filter_filled(scope, filter_params[:filled])

        prepare_records(scope.with_translations.includes(*include_scopes))
      end
    end

    def filter_filled(scope, value)
      return scope if value.blank?
      return scope.filled if value == 'true'

      scope
    end

    def filter_open_for_application(scope, filter_value)
      return scope if filter_value.blank?
      return scope.open_for_applications if filter_value == 'true'

      scope.closed_for_applications
    end

    def filter_job_user_jobs(scope, filter_user_id)
      return scope if filter_user_id.blank? || current_user.not_persisted?

      current_user_id = current_user.id.to_s
      user_id = filter_user_id.delete('-')

      # Only allow the user to filter its own job users (avoids info disclosure..)
      return scope unless current_user_id == user_id || current_user.admin?

      # If filter starts with '-', only return non-matching records
      return scope.no_applied_jobs(user_id) if filter_user_id.start_with?('-')

      scope.applied_jobs(user_id)
    end

    def sort_params
      super.tap do |sort|
        # #filled does not exist in the database so we need to translate it to #filled_at
        sort['filled_at'] = sort.delete('filled') if sort.key?('filled')
      end
    end
  end
end
