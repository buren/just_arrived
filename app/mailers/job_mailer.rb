# frozen_string_literal: true
class JobMailer < ApplicationMailer
  def job_match_email(job:, user:, owner:)
    @user_name = user.name
    @owner_email = owner.contact_email
    @job_name = job.name

    @job_url = FrontendRouter.draw(:job, id: job.id)

    mail(to: user.contact_email, subject: I18n.t('mailer.job_match.subject'))
  end

  def job_user_performed_email(job_user:, owner:)
    user = job_user.user
    job = job_user.job
    @user_name = user.name
    @owner_name = owner.name
    @job_name = job.name
    @user_email = user.contact_email

    @job_user_url = FrontendRouter.draw(
      :job_user_for_company,
      job_id: job.id,
      job_user_id: job_user.id
    )

    subject = I18n.t('mailer.job_performed.subject')
    mail(to: owner.contact_email, subject: subject)
  end

  def new_applicant_email(job_user:, owner:)
    user = job_user.user
    job = job_user.job
    @user_name = user.name
    @user_email = user.contact_email
    @user_phone = user.phone

    @job_name = job.name
    @owner_name = owner.name

    @job_user_url = FrontendRouter.draw(
      :job_user_for_company,
      job_id: job.id,
      job_user_id: job_user.id
    )

    subject = I18n.t('mailer.new_applicant.subject')
    mail(to: owner.contact_email, subject: subject)
  end

  def applicant_accepted_email(job_user:, owner:)
    user = job_user.user
    job = job_user.job
    @user_name = user.name
    @owner_email = owner.contact_email
    @job_name = job.name
    @job_address = job.address

    @job_user_url = FrontendRouter.draw(:job_user, job_id: job.id)

    subject = I18n.t('mailer.applicant_accepted.subject')
    mail(to: user.contact_email, subject: subject)
  end

  def applicant_will_perform_email(job_user:, owner:)
    user = job_user.user
    job = job_user.job
    @user_name = user.name
    @user_email = user.contact_email
    @user_phone = user.phone
    @job_name = job.name

    @job_user_url = FrontendRouter.draw(
      :job_user_for_company,
      job_id: job.id,
      job_user_id: job_user.id
    )

    subject = I18n.t('mailer.applicant_will_perform.subject')
    mail(to: owner.contact_email, subject: subject)
  end

  def accepted_applicant_withdrawn_email(job_user:, owner:)
    user = job_user.user
    job = job_user.job
    @user_name = user.name
    @job_name = job.name

    subject = I18n.t('mailer.accepted_applicant_withdrawn.subject')
    mail(to: owner.contact_email, subject: subject)
  end

  def accepted_applicant_confirmation_overdue_email(job_user:, owner:)
    user = job_user.user
    job = job_user.job
    @user_name = user.name
    @job_name = job.name

    @job_users_url = FrontendRouter.draw(:job_users, job_id: job.id)

    subject = I18n.t('mailer.accepted_applicant_confirmation_overdue.subject')
    mail(to: owner.contact_email, subject: subject)
  end

  def job_cancelled_email(job:, user:)
    @job_name = job.name

    @jobs_url = FrontendRouter.draw(:jobs)

    subject = I18n.t('mailer.job_cancelled.subject')
    mail(to: user.contact_email, subject: subject)
  end
end
