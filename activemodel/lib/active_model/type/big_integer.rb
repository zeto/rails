# frozen_string_literal: true

require_relative "integer"

module ActiveModel
  module Type
    class BigInteger < Integer # :nodoc:
      private

        def max_value
          ::Float::INFINITY
        end
    end
  end
end
