Rails.application.configure do
  config.i18n.available_locales = [:fr, :en]
  config.i18n.default_locale = config.i18n.available_locales.first
  config.i18n.raise_on_missing_translations = Rails.env.local?
end
