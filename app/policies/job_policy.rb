# frozen_string_literal: true
class JobPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.visible
      end
    end
  end

  FULL_ATTRIBUTES = [
    :id, :description, :job_date, :hours, :name, :created_at, :updated_at, :latitude,
    :longitude, :street, :zip, :zip_latitude, :zip_longitude
  ].freeze

  RESTICTED_ATTRIBUTES = [
    :id, :description, :job_date, :hours, :name, :created_at, :updated_at, :zip,
    :zip_latitude, :zip_longitude
  ].freeze

  OWNER_ATTRIBUTES = [
    :description, :job_date, :street, :zip, :name, :hours,
    :language_id, :category_id, :hourly_pay_id, skill_ids: []
  ].freeze

  def index?
    true
  end

  alias_method :show?, :index?

  def create?
    company_user?
  end

  def update?
    admin? || owner?
  end

  def matching_users?
    admin? || owner?
  end

  def permitted_attributes
    return [] if no_user?

    if admin? || !record.persisted? || owner?
      OWNER_ATTRIBUTES
    else
      []
    end
  end

  def present_applicants?
    return false if user.nil?

    admin? || owner?
  end

  def present_self_applicant?
    return false if user.nil?

    accepted_applicant?
  end

  def present_attributes
    return RESTICTED_ATTRIBUTES if user.nil?

    if admin? || owner? || accepted_applicant?
      FULL_ATTRIBUTES
    else
      RESTICTED_ATTRIBUTES
    end
  end

  # Methods that don't match any controller action

  def owner?
    record.owner?(user)
  end

  def accepted_applicant?
    record.accepted_applicant?(user)
  end
end
