Rails.application.configure do
  config.i18n.available_locales = [:fr]
  config.i18n.default_locale = config.i18n.available_locales.first
  config.i18n.raise_on_missing_translations = Rails.env.local?

  if Rails.env.local? && defined?(Faker)
    # Setup Faker so that it works both in test and dev console
    Faker::Config.locale = config.i18n.default_locale

    # Workaround for https://github.com/faker-ruby/faker/issues/2987
    # TL;DR Faker I18n falls back to :en, which raises when available_locales doesn't include :en.
    config.i18n.enforce_available_locales = false
  end
end
