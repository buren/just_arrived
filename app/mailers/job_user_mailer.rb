# frozen_string_literal: true

class JobUserMailer < ApplicationMailer
  default from: DEFAULT_SUPPORT_EMAIL

  def new_applicant_job_info_email(job_user:, skills:, languages:)
    user = job_user.user
    @user_name = user.first_name
    @job_name = job_user.job.name

    skill_names = skills.map(&:name)
    language_names = languages.map { |language| language.name_for(I18n.locale) }
    @competence_names = skill_names + language_names

    @user_edit_url = frontend_mail_url(
      :user_basic_data_edit,
      utm_campaign: 'new_applicant_job_info'
    )

    subject = I18n.t('mailer.new_applicant_job_info.subject')
    mail(to: user.contact_email, subject: subject)
  end

  def update_data_reminder_email(job_user:, skills: [], languages: [], missing_cv: true)
    utm_campaign = 'update_data_reminder'
    user = job_user.user
    @job = job_user.job
    @missing_languages = languages
    @missing_skills = skills
    @missing_cv = missing_cv
    @job_url = frontend_mail_url(:job, id: @job.id, utm_campaign: utm_campaign)
    @user_edit_url = frontend_mail_url(:user_basic_data_edit, utm_campaign: utm_campaign) # rubocop:disable Metrics/LineLength

    subject = I18n.t('mailer.update_data_reminder.subject')
    mail(to: user.contact_email, subject: subject)
  end
end
