# frozen_string_literal: true
class User < ApplicationRecord
  include Geocodable
  include SkillMatchable

  MIN_PASSWORD_LENGTH = 6
  ONE_TIME_TOKEN_VALID_FOR_HOURS = 18

  LOCATE_BY = {
    address: { lat: :latitude, long: :longitude }
  }.freeze

  STATUSES = {
    asylum_seeker: 1,
    permanent: 2,
    residence: 3
  }.freeze

  AT_UND = {
    yes: 1,
    no: 2
  }.freeze

  attr_accessor :password

  after_validation :set_normalized_phone, :set_normalized_ssn

  before_save :encrypt_password

  belongs_to :language
  belongs_to :company

  has_many :auth_tokens, class_name: 'Token'

  has_many :user_skills
  has_many :skills, through: :user_skills

  has_many :owned_jobs, class_name: 'Job', foreign_key: 'owner_user_id'

  has_many :job_users
  has_many :jobs, through: :job_users

  has_many :user_languages
  has_many :languages, through: :user_languages

  has_many :written_comments, class_name: 'Comment', foreign_key: 'owner_user_id'

  has_many :chat_users
  has_many :chats, through: :chat_users

  has_many :messages, class_name: 'Message', foreign_key: 'author_id'

  has_many :user_images

  validates :language, presence: true
  validates :email, presence: true, uniqueness: true
  validates :first_name, length: { minimum: 2 }, allow_blank: false
  validates :last_name, length: { minimum: 2 }, allow_blank: false
  validates :phone, length: { minimum: 9 }, uniqueness: true, allow_blank: false
  validates :description, length: { minimum: 10 }, allow_blank: true
  validates :street, length: { minimum: 5 }, allow_blank: true
  validates :zip, length: { minimum: 5 }, allow_blank: true
  validates :password, length: { minimum: MIN_PASSWORD_LENGTH }, allow_blank: false, on: :create # rubocop:disable Metrics/LineLength
  validates :ssn, uniqueness: true, allow_blank: false
  validates :frilans_finans_id, uniqueness: true, allow_nil: true
  validates :country_of_origin, inclusion: { in: ISO3166::Country.translations.keys }, allow_blank: true # rubocop:disable Metrics/LineLength

  # NOTE: Figure out a good way to validate :current_status and :at_und
  #       see https://github.com/rails/rails/issues/13971

  validate :validate_arrived_at_date
  validate :validate_language_id_in_available_locale
  validate :validate_format_of_phone_number
  validate :validate_swedish_phone_number
  validate :validate_swedish_ssn
  validate :validate_arrival_date_in_past

  scope :admins, -> { where(admin: true) }
  scope :company_users, -> { where.not(company: nil) }
  scope :regular_users, -> { where(company: nil) }
  scope :visible, -> { where.not(banned: true) }
  scope :valid_one_time_tokens, lambda {
    where('one_time_token_expires_at > ?', Time.zone.now)
  }
  scope :frilans_finans_users, -> { where.not(frilans_finans_id: nil) }
  scope :needs_frilans_finans_id, -> { where(frilans_finans_id: nil) }
  scope :anonymized, -> { where(anonymized: true) }
  scope :not_anonymized, -> { where(anonymized: false) }

  enum current_status: STATUSES
  enum at_und: AT_UND

  # Don't change the order or remove any items in the array,
  # only additions are allowed
  NOTIFICATIONS = %w(
    accepted_applicant_confirmation_overdue
    accepted_applicant_withdrawn
    applicant_accepted
    applicant_will_perform
    invoice_created
    job_user_performed
    job_cancelled
    new_applicant
    user_job_match
    new_chat_message
  ).freeze

  def self.find_by_one_time_token(token)
    valid_one_time_tokens.find_by(one_time_token: token)
  end

  def self.find_by_credentials(email_or_phone:, password:)
    user = find_by_email_or_phone(email_or_phone)

    return if user.nil?
    return unless correct_password?(user, password)

    user
  end

  def self.find_token(auth_token)
    Token.find_by(token: auth_token)
  end

  def self.find_token!(auth_token)
    Token.find_by!(token: auth_token)
  end

  def self.find_by_auth_token(auth_token)
    find_token(auth_token).try(:user)
  end

  def self.find_by_auth_token!(auth_token)
    find_token!(auth_token).user
  end

  def self.find_by_phone(phone, normalize: false)
    phone_number = phone
    if normalize
      phone_number = PhoneNumber.normalize(phone_number)
      return if phone_number.nil? # The phone number format is invalid
    end

    find_by(phone: phone_number)
  end

  def self.find_by_email_or_phone(email_or_phone)
    return if email_or_phone.blank?

    find_by(email: email_or_phone) || find_by_phone(email_or_phone, normalize: true)
  end

  def self.correct_password?(user, password)
    password_hash = BCrypt::Engine.hash_secret(password, user.password_salt)
    user.password_hash.eql?(password_hash)
  end

  def self.matches_job(job, distance: 20, strict_match: false)
    lat = job.latitude
    long = job.longitude

    within(lat: lat, long: long, distance: distance).
      order_by_matching_skills(job, strict_match: strict_match)
  end

  def self.accepted_applicant_for_owner?(owner:, user:)
    jobs = owner.owned_jobs & JobUser.accepted_jobs_for(user)
    jobs.any?
  end

  def name
    "#{first_name} #{last_name}"
  end

  def admin?
    admin
  end

  def locale
    return I18n.default_locale.to_s if language.nil?

    language.lang_code
  end

  def frilans_finans_id!
    frilans_finans_id || fail('User has no Frilans Finans id!')
  end

  def auth_token
    auth_tokens.first.try(:token)
  end

  def set_normalized_phone
    self.phone = PhoneNumber.normalize(phone)
  end

  def set_normalized_ssn
    self.ssn = SwedishSSN.normalize(ssn)
  end

  def banned=(value)
    auth_tokens.destroy_all if value
    self[:banned] = value
  end

  def profile_image_token=(token)
    return if token.blank?

    user_image = UserImage.find_by_one_time_token(token)
    self.user_images = [user_image] unless user_image.nil?
  end

  def ignored_notification?(notification)
    ignored_notifications.include?(notification.to_s)
  end

  def ignored_notifications=(notifications)
    self.ignored_notifications_mask = BitmaskField.to_mask(notifications, NOTIFICATIONS)
  end

  def ignored_notifications
    BitmaskField.from_mask(ignored_notifications_mask, NOTIFICATIONS)
  end

  def reset!
    # Update the users attributes and don't validate
    assign_attributes(
      anonymized: true,
      first_name: 'Ghost',
      last_name: 'user',
      email: "ghost+#{SecureGenerator.token(length: 32)}@example.com",
      phone: nil,
      description: 'This user has been deleted.',
      street: 'Stockholm',
      zip: '11120',
      ssn: '0000000000',
      password: SecureGenerator.token
    )
    save!(validate: false)
  end

  def create_auth_token
    token = Token.new
    auth_tokens << token
    token
  end

  def generate_one_time_token(valid_duration: ONE_TIME_TOKEN_VALID_FOR_HOURS.hours)
    self.one_time_token_expires_at = Time.zone.now + valid_duration
    self.one_time_token = SecureGenerator.token
  end

  def self.valid_password?(password)
    return false if password.blank?
    return false unless password.is_a?(String)

    password.length >= 6
  end

  def country_name
    'Sweden'
  end

  def validate_arrival_date_in_past
    return if arrived_at.nil? || arrived_at <= Time.zone.today

    error_message = I18n.t('errors.user.arrived_at_must_be_in_past')
    errors.add(:arrived_at, error_message)
  end

  def validate_language_id_in_available_locale
    language = Language.find_by(id: language_id)
    return if language.nil?

    unless I18n.available_locales.map(&:to_s).include?(language.lang_code)
      errors.add(:language_id, I18n.t('errors.user.must_be_available_locale'))
    end
  end

  def validate_format_of_phone_number
    return if PhoneNumber.valid?(phone)

    error_message = I18n.t('errors.user.must_be_valid_phone_number_format')
    errors.add(:phone, error_message)
  end

  def validate_swedish_phone_number
    return if PhoneNumber.swedish_number?(phone)

    error_message = I18n.t('errors.user.must_be_swedish_phone_number')
    errors.add(:phone, error_message)
  end

  def validate_swedish_ssn
    return unless Rails.configuration.x.validate_swedish_ssn
    return if ssn.blank?
    return if SwedishSSN.valid?(ssn)

    error_message = I18n.t('errors.user.must_be_swedish_ssn')
    errors.add(:ssn, error_message)
  end

  def validate_arrived_at_date
    arrived_at_before_cast = read_attribute_before_type_cast(:arrived_at)
    return if arrived_at_before_cast.nil?
    return unless arrived_at.nil?

    error_message = I18n.t('errors.general.must_be_valid_date')
    errors.add(:arrived_at, error_message)
  end

  private

  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end
  end
end

# == Schema Information
#
# Table name: users
#
#  id                             :integer          not null, primary key
#  email                          :string
#  phone                          :string
#  description                    :text
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  latitude                       :float
#  longitude                      :float
#  language_id                    :integer
#  anonymized                     :boolean          default(FALSE)
#  password_hash                  :string
#  password_salt                  :string
#  admin                          :boolean          default(FALSE)
#  street                         :string
#  zip                            :string
#  zip_latitude                   :float
#  zip_longitude                  :float
#  first_name                     :string
#  last_name                      :string
#  ssn                            :string
#  company_id                     :integer
#  banned                         :boolean          default(FALSE)
#  job_experience                 :text
#  education                      :text
#  one_time_token                 :string
#  one_time_token_expires_at      :datetime
#  ignored_notifications_mask     :integer
#  frilans_finans_id              :integer
#  frilans_finans_payment_details :boolean          default(FALSE)
#  competence_text                :text
#  current_status                 :integer
#  at_und                         :integer
#  arrived_at                     :date
#  country_of_origin              :string
#
# Indexes
#
#  index_users_on_company_id         (company_id)
#  index_users_on_email              (email) UNIQUE
#  index_users_on_frilans_finans_id  (frilans_finans_id) UNIQUE
#  index_users_on_language_id        (language_id)
#  index_users_on_one_time_token     (one_time_token) UNIQUE
#  index_users_on_ssn                (ssn) UNIQUE
#
# Foreign Keys
#
#  fk_rails_45f4f12508  (language_id => languages.id)
#  fk_rails_7682a3bdfe  (company_id => companies.id)
#
