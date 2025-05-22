Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer, fields: [:uid], uid_field: :uid if Rails.env.local?

  scope = "openid email given_name usual_name siret organizational_unit belonging_population"
  provider :proconnect, Rails.application.credentials.proconnect[Rails.env].to_h.merge(scope:)
end

# Make Omniauth compatible with rack_csrf
OmniAuth::AuthenticityTokenProtection.default_options(key: "csrf.token", authenticity_param: "_csrf")
