source "https://rubygems.org"

ruby file: ".ruby-version"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.3"
gem "rails-i18n"

# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.6"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Dart SASS [https://github.com/rails/dartsass-rails]
gem "dartsass-rails"

# Bundle CSV, since it is no longer in standard library
gem "csv"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:windows, :jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
# Add a web interface to control jobs
gem "mission_control-jobs", "~> 1.1"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Monitor errors and performance
gem "vernier"
gem "sentry-ruby"
gem "sentry-rails"

# Allow I18N URLs
gem "addressable", "~> 2.8"

# Pagination
gem "pagy"

# ViewComponents
gem "view_component"

# Markdown in views
gem "markdown_views"

# DSFR utilities
gem "dsfr-assets"
gem "dsfr-form_builder"
gem "dsfr-view-components"

gem "friendly_id"

# Manage external authentication
# FIXME: until https://github.com/omniauth/omniauth/pull/1146
gem "omniauth", github: "freesteph/omniauth", branch: "fix/dont-call-setup-phase-in-test-mode"
gem "omniauth-proconnect"
gem "omniauth-rails_csrf_protection"

# Crawl websites using a headless Chrome browser, controlled by Ferrum
gem "ferrum"

# State machine
gem "statesman"

# Pure Ruby HTTP client for simple requests
gem "http"

# Detect main language from text
gem "cld"

group :development, :test do
  gem "debug"

  # FIXME: ideally we all migrate to Ruby's debug above
  gem "pry-rails"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-watcher"
end

group :development do
  # Print validation error messages in console
  gem "whiny_validation"
  # Open pry when using rails console
  gem "better_errors"
  gem "binding_of_caller"

  # Profile app in development
  gem "rack-mini-profiler"
  gem "memory_profiler"
  gem "stackprof"
end

group :test do
  gem "capybara"
  gem "cucumber-rails", require: false
  gem "betagouv-cucumber-steps", require: false
  gem "database_cleaner"
  gem "guard"
  gem "guard-cucumber"
  gem "guard-rspec"
  gem "rubocop-capybara"
  gem "rubocop-factory_bot"
  gem "rubocop-rails"
  gem "rubocop-rspec"
  gem "rubocop-rspec_rails"
  gem "rspec"
  # Simplify testing common Rails functionality
  gem "shoulda-matchers"

  # Allow stubbing requests during tests
  gem "webmock"

  # Allow testing accessibility using Axe-core. Only available in JS feature tests
  gem "axe-core-capybara", "~> 4.9"
  gem "axe-core-rspec", "~> 4.8"
  gem "selenium-webdriver", "~> 4.37"
end
