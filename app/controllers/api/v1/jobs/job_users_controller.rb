# frozen_string_literal: true
module Api
  module V1
    module Jobs
      class JobUsersController < BaseController
        before_action :require_user
        before_action :set_job
        before_action :set_user, only: [:show, :update, :destroy]

        resource_description do
          resource_id 'job_users'
          short 'API for managing job users'
          name 'Job users'
          description '
            Job users is the relationship between a job and a users.
          '
          formats [:json]
          api_versions '1.0'
        end

        api :GET, '/jobs/:job_id/users', 'Show job users'
        description 'Returns list of job users if the user is allowed.'
        error code: 401, desc: 'Unauthorized'
        def index
          authorize(JobUser)

          page_index = params[:page].to_i
          @users = @job.users.page(page_index)
          render json: @users
        end

        api :GET, '/jobs/:job_id/users/:id', 'Show job user'
        description 'Returns user.'
        error code: 401, desc: 'Unauthorized'
        example Doxxer.read_example(User)
        def show
          authorize(JobUser)

          render json: @user
        end

        api :POST, '/jobs/:job_id/users/', 'Create new job user'
        description 'Creates and returns new job user if the user is allowed.'
        example Doxxer.read_example(User)
        error code: 400, desc: 'Bad request'
        error code: 422, desc: 'Unprocessable entity'
        def create
          authorize(JobUser)

          @job_user = JobUser.new
          @job_user.user = current_user
          @job_user.job = @job

          if @job_user.save
            NewApplicantNotifier.call(job_user: @job_user)
            render json: @user, status: :created
          else
            render json: @job_user.errors, status: :unprocessable_entity
          end
        end

        api :PATCH, '/jobs/:job_id/users/', 'Update job user'
        description 'Updates a job user if the user is allowed.'
        error code: 400, desc: 'Bad request'
        error code: 401, desc: 'Unauthorized'
        error code: 422, desc: 'Unprocessable entity'
        param :data, Hash, desc: 'Top level key', required: true do
          param :attributes, Hash, desc: 'Job user attributes', required: true do
            param :accepted, [true], desc: 'User accepted', required: true
          end
        end
        def update
          authorize(JobUser)

          job_user = @job.find_applicant(@user)
          job_user.accept if jsonapi_params[:accepted]

          if job_user.save
            ApplicantAcceptedNotifier.call(job: @job, user: @user)
            head :no_content
          else
            render json: job_user.errors, status: :unprocessable_entity
          end
        end

        api :DELETE, '/jobs/:job_id/users/:id', 'Delete user user'
        description 'Deletes job user if the user is allowed.'
        error code: 401, desc: 'Unauthorized'
        def destroy
          authorize(JobUser)

          @job_user = @job.job_users.find_by!(user: @user)

          @job_user.destroy
          head :no_content
        end

        private

        def set_job
          @job = Job.find(params[:job_id])
        end

        def set_user
          @user = @job.users.find(params[:id])
        end

        def pundit_user
          JobUserPolicy::Context.new(current_user, @job, @user)
        end
      end
    end
  end
end
