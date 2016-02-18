# frozen_string_literal: true
require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  let(:user) { mock_model User, name: 'User', email: 'user@example.com' }
  let(:owner) { mock_model User, name: 'Owner', email: 'owner@example.com' }
  let(:job) { mock_model Job, name: 'Job name' }

  describe '#welcome_email' do
    let(:mail) { UserMailer.welcome_email(user: user) }

    it 'renders the subject' do
      expect(mail.subject).to eql('Welcome to Just Arrived!')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eql([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eql(['hello@justarrived.se'])
    end

    it 'assigns @user_name' do
      expect(mail.body.encoded).to match(user.name)
    end
  end

  describe '#job_match_email' do
    let(:mail) do
      UserMailer.job_match_email(job: job, user: user, owner: owner)
    end

    it 'renders the subject' do
      expect(mail.subject).to eql('Congrats! You have a new job match.')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eql([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eql(['hello@justarrived.se'])
    end

    it 'assigns @user_name' do
      expect(mail.body.encoded).to match(user.name)
    end

    it 'assigns @owner_email' do
      expect(mail.body.encoded).to match(owner.email)
    end

    it 'assigns @job_name' do
      expect(mail.body.encoded).to match(job.name)
    end
  end

  describe '#job_performed_accept_email' do
    let(:mail) do
      UserMailer.job_performed_accept_email(job: job, user: user, owner: owner)
    end

    it 'renders the subject' do
      subject = 'Congrats! A job you performed has been accepted.'
      expect(mail.subject).to eql(subject)
    end

    it 'renders the receiver email' do
      expect(mail.to).to eql([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eql(['hello@justarrived.se'])
    end

    it 'assigns @user_name' do
      expect(mail.body.encoded).to match(user.name)
    end

    it 'assigns @owner_name' do
      expect(mail.body.encoded).to match(owner.name)
    end

    it 'assigns @job_name' do
      expect(mail.body.encoded).to match(job.name)
    end
  end

  describe '#job_performed_email' do
    let(:mail) do
      UserMailer.job_performed_email(job: job, user: user, owner: owner)
    end

    it 'renders the subject' do
      subject = 'Congrats! A job you ordered has been performed.'
      expect(mail.subject).to eql(subject)
    end

    it 'renders the receiver email' do
      expect(mail.to).to eql([owner.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eql(['hello@justarrived.se'])
    end

    it 'assigns @user_name' do
      expect(mail.body.encoded).to match(user.name)
    end

    it 'assigns @owner_name' do
      expect(mail.body.encoded).to match(owner.name)
    end

    it 'assigns @job_name' do
      expect(mail.body.encoded).to match(job.name)
    end
  end

  describe '#new_applicant_email' do
    let(:mail) do
      UserMailer.new_applicant_email(job: job, user: user, owner: owner)
    end

    it 'renders the subject' do
      subject = 'Congrats! You have a new applicant.'
      expect(mail.subject).to eql(subject)
    end

    it 'renders the receiver email' do
      expect(mail.to).to eql([owner.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eql(['hello@justarrived.se'])
    end

    it 'assigns @user_name' do
      expect(mail.body.encoded).to match(user.name)
    end

    it 'assigns @owner_name' do
      expect(mail.body.encoded).to match(owner.name)
    end

    it 'assigns @job_name' do
      expect(mail.body.encoded).to match(job.name)
    end
  end

  describe '#applicant_accepted_email' do
    let(:mail) do
      UserMailer.applicant_accepted_email(job: job, user: user, owner: owner)
    end

    it 'renders the subject' do
      subject = 'Congrats! You got a job.'
      expect(mail.subject).to eql(subject)
    end

    it 'renders the receiver email' do
      expect(mail.to).to eql([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eql(['hello@justarrived.se'])
    end

    it 'assigns @user_name' do
      expect(mail.body.encoded).to match(user.name)
    end

    it 'assigns @owner_email' do
      expect(mail.body.encoded).to match(owner.email)
    end

    it 'assigns @job_name' do
      expect(mail.body.encoded).to match(job.name)
    end
  end
end
