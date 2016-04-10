# frozen_string_literal: true

module FrilansFinansApi
  class Company
    def self.create(attributes:, client: DEFAULT_CLIENT_KLASS.new)
      response = client.create_company(attributes: attributes)
      Document.new(response.body)
    end
  end
end
