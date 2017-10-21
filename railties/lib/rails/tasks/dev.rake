# frozen_string_literal: true

require_relative "../dev_caching"

namespace :dev do
  desc "Toggle development mode caching on/off"
  task :cache do
    Rails::DevCaching.enable_by_file
  end
end
