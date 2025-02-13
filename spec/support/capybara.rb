# frozen_string_literal: true

Capybara.register_driver :headless_firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument "-headless"
  Capybara::Selenium::Driver.new app, browser: :firefox, options:
end

Capybara.register_driver :firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  Capybara::Selenium::Driver.new app, browser: :firefox, options:
end

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  Capybara::Selenium::Driver.new app, browser: :chrome, options:
end

Capybara.javascript_driver = ENV.fetch("CAPYBARA_JS_DRIVER", :headless_firefox).to_sym

Capybara.default_max_wait_time = 3
Capybara.server_port = 31337
Capybara.server = :puma, { Silent: true }

# Silence upstream deprecation warning. See https://github.com/teamcapybara/capybara/issues/2779
Selenium::WebDriver.logger.ignore(:clear_local_storage, :clear_session_storage)
