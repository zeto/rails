# frozen_string_literal: true

require_relative "../../string_inquirer"

class String
  # Wraps the current string in the <tt>ActiveSupport::StringInquirer</tt> class,
  # which gives you a prettier way to test for equality.
  #
  #   env = 'production'.inquiry
  #   env.production?  # => true
  #   env.development? # => false
  def inquiry
    ActiveSupport::StringInquirer.new(self)
  end
end
