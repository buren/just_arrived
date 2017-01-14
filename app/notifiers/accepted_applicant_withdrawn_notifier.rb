# frozen_string_literal: true
class AcceptedApplicantWithdrawnNotifier < BaseNotifier
  def self.call(job_user:, owner:)
    notify(user: owner, locale: owner.locale) do
      JobMailer.
        accepted_applicant_withdrawn_email(job_user: job_user, owner: owner).
        deliver_later
    end
  end
end
