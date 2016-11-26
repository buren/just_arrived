# frozen_string_literal: true
module FrilansFinans
  module InvoiceWrapper
    def self.attributes(job:, user:, tax:, ff_user:, pre_report:, express_payment:)
      invoice_users_data = invoice_users(
        job: job,
        user: user,
        ff_user: ff_user,
        express_payment: express_payment
      )

      {
        invoice: {
          invoiceuser: invoice_users_data,
          invoicedate: invoice_dates(job: job)
        }.merge!(invoice_data(job: job, user: user, tax: tax, pre_report: pre_report))
      }
    end

    def self.invoice_data(job:, user:, tax:, pre_report:)
      {
        currency_id: Currency.default_currency&.frilans_finans_id,
        specification: job.invoice_specification,
        amount: job.invoice_amount,
        company_id: job.invoice_company_frilans_finans_id,
        tax_id: tax.id,
        user_id: user.frilans_finans_id,
        pre_report: pre_report
      }
    end

    def self.invoice_users(job:, user:, ff_user:, express_payment: false)
      ff_user_attributes = ff_user.resource.attributes

      if ff_user.resource.attributes
        taxkey_id = ff_user_attributes['default_taxkey_id']
      else
        message = "Missing FF user attributes for user ##{user.id}"
        Rails.logger.warn "WARN -- : #{message}"
        context = { user_id: user.id, job_id: job.id, resource: ff_user.resource.inspect }
        ErrorNotifier.send(message, context: context)
      end

      [{
        user_id: user.frilans_finans_id,
        total: job.invoice_amount,
        taxkey_id: taxkey_id,
        allowance: 0,
        travel: 0,
        save_vacation_pay: 0,
        save_itp: 0,
        express_payment: express_payment ? 1 : 0
      }]
    end

    def self.invoice_dates(job:)
      workdays = job.workdays
      hours_per_date = job.hours / workdays.length
      # Frilans Finans wants hours rounded to the closets half
      hours_per_date_rounded = (hours_per_date * 2).round.to_f / 2
      workdays.map do |date|
        {
          date: date,
          hours: hours_per_date_rounded
        }
      end
    end
  end
end
