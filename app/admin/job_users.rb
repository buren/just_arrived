# frozen_string_literal: true

ActiveAdmin.register JobUser do
  menu parent: 'Jobs', priority: 2

  actions :index, :show, :new, :create, :edit, :update

  actions :all, except: [:destroy]
  batch_action :destroy, false
  batch_action :accept_and_notify_user do |ids|
    job_users = JobUser.where(id: ids)
    success_count = 0
    ignore_count = 0
    fail_ids = []

    job_users.each do |job_user|
      if job_user.accepted
        ignore_count += 1
        next
      end

      if job_user.update(accepted: true)
        owner = job_user.job.owner
        success_count += 1
        ApplicantAcceptedNotifier.call(job_user: job_user, owner: owner)
      else
        fail_ids << job_user.id
      end
    end

    if fail_ids.empty?
      notice = I18n.t(
        'admin.job_user.batch_action.accepted.success_msg',
        success_count: success_count,
        ignore_count: ignore_count
      )
      redirect_to collection_path, notice: notice
    else
      notice = I18n.t(
        'admin.job_user.batch_action.accepted.fail_msg',
        fail_count: fail_ids.length,
        fail_ids: fail_ids.join(', '),
        success_count: success_count,
        ignore_count: ignore_count
      )
      redirect_to collection_path, alert: notice
    end
  end

  batch_action :ask_for_job_information, confirm: I18n.t('admin.job_user.batch_action.ask_for_job_information.confirm') do |ids| # rubocop:disable Metrics/LineLength
    job_users = collection.where(id: ids)
    job_users.each do |job_user|
      AskForJobInformationJob.perform_later(job_user)
    end

    notice = I18n.t('admin.job_user.batch_action.ask_for_job_information.success')
    redirect_to collection_path, notice: notice
  end

  batch_action :shortlist, confirm: I18n.t('admin.job_user.batch_action.shortlist.confirm') do |ids| # rubocop:disable Metrics/LineLength
    job_users = collection.where(id: ids)
    job_users.map { |job_user| job_user.update(shortlisted: true) }

    notice = I18n.t(
      'admin.job_user.batch_action.shortlist.success', count: job_users.length
    )
    redirect_to collection_path, notice: notice
  end

  batch_action :reject_and_notify, confirm: I18n.t('admin.job_user.batch_action.reject.confirm') do |ids| # rubocop:disable Metrics/LineLength
    job_users = collection.where(id: ids)
    job_users.map do |job_user|
      unless job_user.rejected
        job_user.update(rejected: true)
        JobMailer.applicant_rejected_email(job_user: job_user).deliver_later
      end
    end

    notice = I18n.t(
      'admin.job_user.batch_action.reject.success', count: job_users.length
    )
    redirect_to collection_path, notice: notice
  end

  batch_action :send_communication_template_to, form: lambda {
    {
      type: %w[email sms both],
      template_id: CommunicationTemplate.to_form_array,
      job_id: Job.to_form_array(include_blank: true)
    }
  } do |ids, inputs|
    type = inputs['type']
    job_id = inputs['job_id']
    template_id = inputs['template_id']

    users = JobUser.where(id: ids).includes(:user).map(&:user)
    job = Job.with_translations.find_by(id: job_id)
    template = CommunicationTemplate.with_translations.find(template_id)

    response = SendAdminCommunicationTemplate.call(
      users: users,
      job: job,
      communcation_template: template,
      type: type
    )

    notice = response[:message]
    if response[:success]
      redirect_to collection_path, notice: notice
    else
      redirect_to collection_path, alert: notice
    end
  end

  batch_action :send_message_to, form: lambda {
    {
      type: %w[email sms both],
      language_id: Language.system_languages.to_form_array,
      subject:  :text,
      message:  :textarea
    }
  } do |ids, inputs|
    response = SendAdminMessage.call(
      users: JobUser.where(id: ids).includes(:user).map(&:user),
      type: inputs['type'],
      subject: inputs['subject'],
      template: inputs['message'],
      language_id: inputs['language_id']
    )
    notice = response[:message]

    if response[:success]
      redirect_to collection_path, notice: notice
    else
      redirect_to collection_path, alert: notice
    end
  end

  scope :all
  scope :visible, default: true
  scope :shortlisted
  scope :will_perform
  scope :not_pre_reported

  filter :just_arrived_contact, collection: -> { User.delivery_users }
  filter :user_documents_text_content_cont, as: :string, label: I18n.t('admin.user.resume_search_label') # rubocop:disable Metrics/LineLength
  filter :tags
  filter :languages
  filter :user_recruiter_activities_body_cont, as: :string, label: I18n.t('admin.recruiter_activity.filter_body_label') # rubocop:disable Metrics/LineLength
  filter :user_recruiter_activities_activity_id_eq, as: :select, collection: -> { Activity.all.order(name: :asc) }, label: I18n.t('admin.recruiter_activity.filter_activity_label') # rubocop:disable Metrics/LineLength
  filter :user_recruiter_activities_author_id_eq, as: :select, collection: -> { User.admins }, label: I18n.t('admin.recruiter_activity.filter_author_label') # rubocop:disable Metrics/LineLength
  filter :occupations, collection: -> { Occupation.with_translations.order_by_name }
  filter :job, collection: -> { Job.with_translations.order_by_name.limit(1000) }
  filter :accepted
  filter :will_perform
  filter :performed
  filter :shortlisted
  filter :updated_at
  filter :created_at
  filter :translations_apply_message_cont, as: :string, label: I18n.t('admin.job_user.apply_message') # rubocop:disable Metrics/LineLength

  index do
    selectable_column

    users = User.
            association_count(JobUser).
            where(id: job_users.map(&:user_id))

    column :user do |job_user|
      user = job_user.user
      link_to(user.name, admin_job_user_path(job_user))
    end

    column :applications, sortable: 'job_users_count' do |job_user|
      user = job_user.user
      found_user = users.detect { |count_user| count_user.id == job_user.user.id }

      column_content = safe_join([
                                   user_icon_png(html_class: 'table-column-icon'),
                                   found_user.job_user_count
                                 ])
      link_path = admin_job_users_path + AdminHelpers::Link.query(:user_id, user.id)

      link_to(column_content, link_path, class: 'table-column-icon-link')
    end

    if params.dig(:q, :job_id_eq).blank?
      column :job_id do |job_user|
        job = job_user.job
        link_to("##{job.id}", admin_job_path(job))
      end
    end
    column :user_city, sortable: 'users.city' do |job_user|
      job_user.user.city
    end

    column(:tags) { |job_user| user_tag_badges(user: job_user) }

    column :applied_at, sortable: 'job_users.created_at' do |job_user|
      job_user.created_at.strftime('%Y-%m-%d')
    end
    column :status do |job_user|
      job_user_current_status_badge(job_user.current_status)
    end
    column :comment do |job_user|
      job_user.active_admin_comments.max_by(&:created_at)&.body
    end
  end

  show do
    user = job_user.user
    support_chat = Chat.find_or_create_support_chat(job_user.user)
    resume = user.user_documents.cv.last&.document

    recruiter_activities = job_user.user.
                           recruiter_activities.
                           order(id: :desc).
                           includes(:activity, :author)

    locals = {
      job_user: job_user,
      recruiter_activities: recruiter_activities,
      total_job_applications: user.job_users.count,
      support_chat: support_chat,
      user: user,
      resume: resume
    }

    if job_user.job.ended? && params[:full].blank?
      render partial: 'job_ended_view', locals: locals
    else
      render partial: 'show', locals: locals
    end

    active_admin_comments
  end

  include AdminHelpers::MachineTranslation::Actions

  sidebar :job_user_relations, only: %i(show edit) do
    render partial: 'admin/job_users/relations_list', locals: { job_user: job_user }
  end

  sidebar :user_relations, only: %i(show edit) do
    render partial: 'admin/users/relations_list', locals: { user: job_user.user }
  end

  sidebar :job_relations, only: %i(show edit) do
    render partial: 'admin/jobs/relations_list', locals: { job: job_user.job }
  end

  sidebar :latest_applications, only: %i(show edit) do
    user = job_user.user
    ul do
      user.job_users.
        includes(job: %i(language translations)).
        recent(50).
        each do |job_user|

        li link_to("##{job_user.id} " + job_user.job.name, admin_job_user_path(job_user))
      end
    end
  end

  sidebar :documents, only: %i(show edit) do
    user = job_user.user
    user_documents = user.user_documents.recent(50).includes(:document)

    locals = { user_documents: user_documents }
    render partial: 'admin/users/documents_list', locals: locals
  end

  set_job_user_translation = lambda do |job_user, permitted_params|
    return unless job_user.persisted? && job_user.valid?

    translation_params = {
      name: permitted_params.dig(:job_user, :apply_message)
    }
    job_user.set_translation(translation_params)
  end

  set_job_filled_status = lambda do |job_user|
    return unless job_user.persisted? && job_user.valid?
    job = job_user.job

    # update job fill status
    if job_user.public_send(job.accept_method_sym) && !job.filled
      job.filled = true
      job.save!
    end
  end

  after_save do |job_user|
    set_job_user_translation.call(job_user, permitted_params)
    set_job_filled_status.call(job_user)
  end

  sidebar :app, only: %i(show edit) do
    ul do
      li(
        link_to(
          I18n.t('admin.view_in_app.job'),
          FrontendRouter.draw(:job, id: job_user.job_id, utm_medium: UTM_ADMIN_MEDIUM),
          target: '_blank'
        )
      )
    end
  end

  sidebar :latest_activity, only: %i[show edit] do
    locals = { user: job_user.user }
    render partial: 'admin/users/latest_activity', locals: locals
  end

  permit_params do
    %i(
      user_id job_id accepted will_perform performed apply_message
      application_withdrawn shortlisted rejected
    )
  end

  controller do
    def scoped_collection
      super.includes(
        :user,
        :tags,
        :active_admin_comments,
        :frilans_finans_invoice,
        job: %i(translations language)
      )
    end

    def find_resource
      JobUser.includes(
        user: [
          { user_skills: [{ skill: %i(language translations) }] },
          { user_languages: %i(language) },
          { chats: [:users, { messages: %i(author language translations) }] }
        ]
      ).
        where(id: params[:id]).
        first!
    end
  end
end
