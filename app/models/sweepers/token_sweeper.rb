# frozen_string_literal: true
module Sweepers
  class TokenSweeper
    def self.destroy_expired_tokens(scope = Token)
      scope.ready_for_deletion.find_each(batch_size: 1000, &:destroy!)
    end
  end
end
