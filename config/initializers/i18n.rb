# frozen_string_literal: true

Rails.application.configure do
  config.i18n.available_locales = [:fr]
  config.i18n.default_locale = :fr
  config.time_zone = "Europe/Paris"
  config.i18n.raise_on_missing_translations = Rails.env.local?
end
