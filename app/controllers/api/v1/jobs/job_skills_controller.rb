# frozen_string_literal: true
module Api
  module V1
    module Jobs
      class JobSkillsController < BaseController
        before_action :set_job
        before_action :set_skill, only: [:show, :destroy]
        before_action :set_job_skill, only: [:show, :destroy]

        resource_description do
          resource_id 'job_skills'
          short 'API for managing job skills'
          name 'Job skills'
          description '
            Job skills is the relationship between a job and a skills.
          '
          formats [:json]
          api_versions '1.0'
        end

        api :GET, '/jobs/:job_id/skills', 'Show user skills'
        description 'Returns list of job skills.'
        error code: 404, desc: 'Not found'
        example Doxxer.read_example(JobSkill, plural: true)
        def index
          authorize(JobSkill)

          job_skills_index = Index::JobSkillsIndex.new(self)
          @job_skills = job_skills_index.job_skills(@job.job_skills)

          api_render(@job_skills, included: job_skills_index.included)
        end

        api :GET, '/jobs/:job_id/skills/:id', 'Show user skill'
        error code: 404, desc: 'Not found'
        description 'Returns skill.'
        example Doxxer.read_example(JobSkill)
        def show
          authorize(JobSkill)

          api_render(@job_skill, included: 'skill')
        end

        api :POST, '/jobs/:job_id/skills/', 'Create new job skill'
        description 'Creates and returns new job skill if the user is allowed.'
        error code: 400, desc: 'Bad request'
        error code: 404, desc: 'Not found'
        error code: 422, desc: 'Unprocessable entity'
        error code: 401, desc: 'Unauthorized'
        param :data, Hash, desc: 'Top level key', required: true do
          param :attributes, Hash, desc: 'Skill attributes', required: true do
            param :id, Integer, desc: 'Skill id', required: true
          end
        end
        example Doxxer.read_example(JobSkill)
        def create
          authorize(JobSkill)

          @job_skill = JobSkill.new
          @job_skill.skill = Skill.find_by(id: skill_params[:id])
          @job_skill.job = @job

          if @job_skill.save
            api_render(@job_skill, included: 'skill', status: :created)
          else
            respond_with_errors(@job_skill)
          end
        end

        api :DELETE, '/jobs/:job_id/skills/:id', 'Delete user skill'
        description 'Deletes job skill if the user is allowed.'
        error code: 401, desc: 'Unauthorized'
        error code: 404, desc: 'Not found'
        def destroy
          authorize(JobSkill)

          @job_skill.destroy
          head :no_content
        end

        private

        def set_job
          @job = Job.find(params[:job_id])
        end

        def set_skill
          @skill = @job.skills.find(params[:id])
        end

        def set_job_skill
          @job_skill = @job.job_skills.find_by!(skill: @skill)
        end

        def skill_params
          jsonapi_params.permit(:id)
        end

        def pundit_user
          JobSkillPolicy::Context.new(current_user, @job)
        end
      end
    end
  end
end
