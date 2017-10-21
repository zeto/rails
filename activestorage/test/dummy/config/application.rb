# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "sprockets/railtie"
require "active_storage/engine"
#require "action_mailer/railtie"
#require "rails/test_unit/railtie"
#require "action_cable/engine"


Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults 5.1

    config.active_storage.service = :local
  end
end
