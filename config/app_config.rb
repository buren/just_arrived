# frozen_string_literal: true

require_relative 'app_env'

class AppConfig
  def self.env
    @env ||= default_env
  end

  def self.env=(env)
    @env = AppEnv.new(env: env)
  end

  def self.default_env
    @env = AppEnv.new
  end

  def self.sidekiq_web_enabled?
    Rails.env.development?
  end

  def self.anonymization_delay_days
    Integer(env.fetch('ANONYMIZATION_DELAY_DAYS', 3))
  end

  def self.keep_applicant_data_years
    Integer(env.fetch('KEEP_APPLICANT_DATA_YEARS', 2))
  end

  def self.apache_tika_url
    env['APACHE_TIKA_URL']
  end

  def self.document_parser_active?
    truthy?(env['DOCUMENT_PARSER_ACTIVE'])
  end

  def self.default_mailer_url_host
    'api.justarrived.se'
  end

  def self.new_applicant_email_active?
    value = env['NEW_APPLICANT_EMAIL_ACTIVE']
    return true if value.nil?

    truthy?(value)
  end

  def self.cv_template_url
    'https://justarrived.se/assets/files/CV-template.docx'
  end

  def self.default_staffing_company_id
    env['DEFAULT_STAFFING_COMPANY_ID']
  end

  # 3rd party job boards

  def self.linkedin_default_locale
    env.fetch('LINKEDIN_DEFAULT_LOCALE', 'sv')
  end

  def self.linkedin_job_records_feed_limit
    Integer(env.fetch('LINKEDIN_JOB_RECORDS_FEED_LIMIT', 300))
  end

  def self.arbetsformedlingen_default_locale
    env.fetch('ARBETSFORMEDLINGEN_DEFAULT_LOCALE', 'sv')
  end

  def self.arbetsformedlingen_default_publisher_email
    env['ARBETSFORMEDLINGEN_DEFAULT_PUBLISHER_EMAIL']
  end

  def self.arbetsformedlingen_default_publisher_name
    env['ARBETSFORMEDLINGEN_DEFAULT_PUBLISHER_NAME']
  end

  def self.blocketjobb_default_locale
    env.fetch('BLOCKETJOBB_DEFAULT_LOCALE', 'sv')
  end

  def self.blocketjobb_customer_logo_url
    env['BLOCKETJOBB_CUSTOMER_LOGO_URL']
  end

  def self.metrojobb_default_locale
    env.fetch('METROJOBB_DEFAULT_LOCALE', 'sv')
  end

  def self.metrojobb_customer_logo_url
    env['METROJOBB_CUSTOMER_LOGO_URL']
  end

  # Application settings

  def self.allow_regular_users_to_create_jobs?
    truthy?(env['ALLOW_REGULAR_USERS_TO_CREATE_JOBS'])
  end

  def self.globally_ignored_notifications
    (env['GLOBALLY_IGNORED_NOTIFICATIONS'] || '').
      split(',').
      map { |name| name.strip.downcase }.
      compact
  end

  def self.new_job_request_email_recipients
    env.fetch('NEW_JOB_REQUEST_EMAIL_RECIPIENTS', '').split(',').
      map { |name| name.strip.downcase }.
      compact
  end

  def self.support_email
    env['DEFAULT_SUPPORT_EMAIL']
  end

  def self.managed_email_username
    env['MANAGED_EMAIL_USERNAME']
  end

  def self.managed_email_hostname
    env['MANAGED_EMAIL_HOSTNAME']
  end

  def self.invoice_company_frilans_finans_id
    env['INVOICE_COMPANY_FRILANS_FINANS_ID']
  end

  def self.max_jobs_in_digest_notification
    Integer(env.fetch('MAX_JOBS_IN_DIGEST_NOTIFICATION', 10))
  end

  def self.default_records_per_page
    Integer(env.fetch('DEFAULT_RECORDS_PER_PAGE', 10))
  end

  def self.default_max_records_per_page
    Integer(env.fetch('DEFAULT_MAX_RECORDS_PER_PAGE', 50))
  end

  def self.max_records_per_page
    env.fetch('MAX_RECORDS_PER_PAGE', 1000)
  end

  def self.frilans_finans_company_creator_user_id
    env['FRILANS_FINANS_COMPANY_CREATOR_USER_ID']
  end

  def self.frilans_finans_base_uri
    env['FRILANS_FINANS_BASE_URI']
  end

  def self.user_one_time_token_valid_for_hours
    Integer(env.fetch('USER_ONE_TIME_TOKEN_VALID_FOR_HOURS', 18))
  end

  def self.max_password_length
    Integer(env.fetch('MAX_PASSWORD_LENGTH', 50))
  end

  def self.min_password_length
    Integer(env.fetch('MIN_PASSWORD_LENGTH', 6))
  end

  def self.frilans_finans_active?
    truthy?(env['FRILANS_FINANS_ACTIVE'])
  end

  def self.cors_whitelist
    env.
      fetch('CORS_WHITELIST', '').
      split(',').
      map(&:strip)
  end

  def self.send_sms_notifications?
    truthy?(env.fetch('SEND_SMS_NOTIFICATIONS', true))
  end

  def self.app_host
    env.fetch('APP_HOST', 'https://api.justarrived.se')
  end

  def self.validate_swedish_ssn
    truthy?(env.fetch('VALIDATE_SWEDISH_SSN', true))
  end

  def self.admin_google_analytics_tracking_id
    env['ADMIN_GOOGLE_ANALYTICS_TRACKING_ID']
  end

  def self.admin_google_analytics_active?
    production? && admin_google_analytics_tracking_id.present?
  end

  def self.new_companies_digest_receiver_email
    env['NEW_COMPANIES_DIGEST_RECEIVER_EMAIL']
  end

  # Application config

  def self.aws_region
    env['AWS_REGION']
  end

  def self.s3_bucket_name
    env['S3_BUCKET_NAME']
  end

  def self.redis_url
    env.fetch('REDIS_URL', 'localhost')
  end

  def self.app_base_url
    env.fetch('APP_BASE_URL', 'https://api.justarrived.se')
  end

  def self.live_frilans_finans_seed?
    !!env.fetch('LIVE_FRILANS_FINANS_SEED', false)
  end

  # Application Server

  def self.db_pool
    env['DB_POOL']
  end

  def self.redis_timeout
    Integer(env.fetch('REDIS_TIMEOUT', 5))
  end

  def self.port
    env.fetch('PORT', 3000)
  end

  def self.max_threads
    Integer(env.fetch('MAX_THREADS', 2))
  end

  def self.web_concurrency
    Integer(env.fetch('WEB_CONCURRENCY', 2))
  end

  # Environment

  def self.production?
    rails_env == 'production'
  end

  def self.rails_env
    env['RAILS_ENV']
  end

  def self.rack_env
    env.fetch('RACK_ENV', 'development')
  end

  def self.rails_log_to_stdout?
    truthy?(env['RAILS_LOG_TO_STDOUT'])
  end

  def self.rails_serve_static_files?
    truthy?(env['RAILS_SERVE_STATIC_FILES'])
  end

  # private

  def self.truthy?(value)
    [true, 'true', 'enabled', 'enable', 'yes', 'y'].include?(value)
  end
end
