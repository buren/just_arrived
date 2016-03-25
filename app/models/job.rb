# frozen_string_literal: true
class Job < ActiveRecord::Base
  include Geocodable
  include SkillMatchable

  LOCATE_BY = {
    address: { lat: :latitude, long: :longitude },
    zip: { lat: :zip_latitude, long: :zip_longitude }
  }.freeze

  ALLOWED_RATES = [70, 80, 100].freeze

  belongs_to :language

  has_one :company, through: :owner

  has_many :job_skills
  has_many :skills, through: :job_skills

  has_many :job_users
  has_many :users, through: :job_users

  has_many :comments, as: :commentable

  validates :language, presence: true
  validates :name, length: { minimum: 2 }, allow_blank: false
  validates :max_rate, inclusion: { in: ALLOWED_RATES }, allow_blank: false
  validates :description, length: { minimum: 10 }, allow_blank: false
  validates :street, length: { minimum: 5 }, allow_blank: false
  validates :zip, length: { minimum: 5 }, allow_blank: false
  validates :job_date, presence: true
  validates :owner, presence: true
  validates :hours, numericality: { greater_than_or_equal_to: 1 }, allow_blank: false

  validate :validate_job_date_in_future

  belongs_to :owner, class_name: 'User', foreign_key: 'owner_user_id'

  scope :visible, -> { where(hidden: false) }

  def self.matches_user(user, distance: 20, strict_match: false)
    lat = user.latitude
    long = user.longitude

    within(lat: lat, long: long, distance: distance).
      order_by_matching_skills(user, strict_match: strict_match)
  end

  def locked_for_changes?
    applicant = applicants.find_by(accepted: true)
    return false unless applicant

    applicant.will_perform
  end

  # Needed for administrate
  # see https://github.com/thoughtbot/administrate/issues/354
  def owner_id
    owner.try!(:id)
  end

  # Needed for administrate
  # see https://github.com/thoughtbot/administrate/issues/354
  def owner_id=(id)
    self.owner = User.find_by(id: id)
  end

  def owner?(user)
    !owner.nil? && owner == user
  end

  def find_applicant(user)
    job_users.find_by(user: user)
  end

  def accepted_applicant?(user)
    !accepted_applicant.nil? && accepted_applicant == user
  end

  def accepted_job_user
    applicants.find_by(accepted: true)
  end

  def accepted_applicant
    accepted_job_user.try!(:user)
  end

  def accept_applicant!(user)
    applicants.find_by(user: user).tap do |applicant|
      applicant.accept
      applicant.save!
    end.reload
  end

  def create_applicant!(user)
    users << user
    user
  end

  def applicants
    job_users
  end

  def started?
    job_date < Time.zone.now
  end

  def validate_job_date_in_future
    return if job_date.nil? || job_date > Time.zone.now

    errors.add(:job_date, I18n.t('errors.job.job_date_in_the_past'))
  end
end

# == Schema Information
#
# Table name: jobs
#
#  id            :integer          not null, primary key
#  max_rate      :integer
#  description   :text
#  job_date      :datetime
#  hours         :float
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  owner_user_id :integer
#  latitude      :float
#  longitude     :float
#  language_id   :integer
#  street        :string
#  zip           :string
#  zip_latitude  :float
#  zip_longitude :float
#  hidden        :boolean          default(FALSE)
#
# Indexes
#
#  index_jobs_on_language_id  (language_id)
#
# Foreign Keys
#
#  fk_rails_70cb33aa57    (language_id => languages.id)
#  jobs_owner_user_id_fk  (owner_user_id => users.id)
#
