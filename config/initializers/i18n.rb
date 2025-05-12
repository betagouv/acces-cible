# frozen_string_literal: true

Rails.application.configure do
  config.i18n.available_locales = [:fr]
  config.i18n.default_locale = :fr
  config.time_zone = "Europe/Paris"
  config.i18n.raise_on_missing_translations = Rails.env.local?

  # Workaround until there's a fix for https://github.com/faker-ruby/faker/issues/2987
  # TL;DR Faker falls back to :en when the current locale doesn't contain a key,
  # but this fails because :en isn't included in config.i18n.available_locales.
  config.i18n.available_locales << :en if Rails.env.test?
end
