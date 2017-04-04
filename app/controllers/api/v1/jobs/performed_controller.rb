# frozen_string_literal: true
module Api
  module V1
    module Jobs
      class PerformedController < BaseController
        resource_description do
          short 'API for job performed'
          name 'Job performed'
          description ''
          formats [:json]
          api_versions '1.0'
        end

        before_action :require_user
        before_action :set_job
        before_action :set_job_user
        before_action :set_user

        after_action :verify_authorized, except: %i(create)

        api :POST, '/jobs/:job_id/users/:job_user_id/performed', 'Confirm performed job'
        description 'Confirm that the job has been performed.'
        error code: 400, desc: 'Bad request'
        error code: 401, desc: 'Unauthorized'
        error code: 404, desc: 'Not found'
        error code: 422, desc: 'Unprocessable entity'
        ApipieDocHelper.params(self)
        example Doxxer.read_example(JobUser, method: :update)
        def create
          authorize(@job_user, :performed?)

          @job_user.performed = true

          if @job_user.save
            performed_notifer_klass.call(job_user: @job_user, owner: @job.owner)

            api_render(@job_user)
          else
            api_render_errors(@job_user)
          end
        end

        private

        def set_job
          @job = policy_scope(Job).find(params[:job_id])
        end

        def set_user
          @user = @job_user.user
        end

        def set_job_user
          @job_user = @job.job_users.find(params[:job_user_id])
        end

        def pundit_user
          JobUserPolicy::Context.new(current_user, @job, @user)
        end

        def performed_notifer_klass
          # JobUserPerformedNotifier
          NilNotifier
        end
      end
    end
  end
end
