# frozen_string_literal: true
class Rating < ApplicationRecord
  SCORE_RANGE = 1..5

  belongs_to :from_user, class_name: 'User', foreign_key: 'from_user_id'
  belongs_to :to_user, class_name: 'User', foreign_key: 'to_user_id'
  belongs_to :job

  has_one :comment, as: :commentable

  validates :job, presence: true

  # rubocop:disable Metrics/LineLength
  validates :score, presence: true, numericality: { only_integer: true }, inclusion: SCORE_RANGE
  validates :from_user, presence: true, uniqueness: { scope: :job_id, message: I18n.t('errors.rating.from_user_rated') }
  validates :to_user, presence: true, uniqueness: { scope: :job_id, message: I18n.t('errors.rating.to_user_rated') }
  # rubocop:enable Metrics/LineLength

  validate :validate_comment_owned_by
  validate :validate_job_invoiced
  validate :validate_job_user_performed
  validate :validate_rating_user

  scope :received_ratings, ->(user) { where(to_user: user) }
  scope :gave_ratings, ->(user) { where(from_user: user) }

  def self.user_allowed_to_rate?(job:, user:)
    return false if job.nil? || user.nil?

    user == job.owner || user == job.accepted_applicant
  end

  def self.average_score(round: nil)
    score = average(:score)
    score = score.round(round) if !score.nil? && round
    score
  end

  def validate_comment_owned_by
    return if comment.nil?

    unless comment.owner == from_user
      errors.add(:comment, I18n.t('errors.rating.comment_user'))
    end
  end

  def by_job_owner?
    return false if from_user.nil? || job.nil?

    from_user == job.owner
  end

  def by_job_user?
    return false if from_user.nil?

    from_user == accepted_user
  end

  def accepted_user
    accepted_job_user&.user
  end

  def accepted_job_user
    @accepted_job_user ||= job&.accepted_job_user
  end

  def validate_job_invoiced
    # Only validate this if the rating is made by the Job#owner
    return unless by_job_owner?
    return if accepted_job_user.nil?

    unless accepted_job_user.invoiced?
      errors.add(:job_user, I18n.t('errors.rating.job_user_concluded'))
    end
  end

  def validate_job_user_performed
    # Only validate this if the rating is made by the job user
    return unless by_job_user?
    return if accepted_job_user.nil?

    unless accepted_job_user.performed?
      errors.add(:job_user, I18n.t('errors.rating.job_user_performed'))
    end
  end

  def validate_rating_user
    [:from_user, :to_user].each do |relation_name|
      user_object = public_send(relation_name)
      unless self.class.user_allowed_to_rate?(job: job, user: user_object)
        errors.add(relation_name, I18n.t('errors.rating.user_allowed_to_rate'))
      end
    end
  end
end

# == Schema Information
#
# Table name: ratings
#
#  id           :integer          not null, primary key
#  from_user_id :integer
#  to_user_id   :integer
#  job_id       :integer
#  score        :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_ratings_on_job_id_and_from_user_id  (job_id,from_user_id) UNIQUE
#  index_ratings_on_job_id_and_to_user_id    (job_id,to_user_id) UNIQUE
#
# Foreign Keys
#
#  ratings_from_user_id_fk  (from_user_id => users.id)
#  ratings_job_id_fk        (job_id => jobs.id)
#  ratings_to_user_id_fk    (to_user_id => users.id)
#
