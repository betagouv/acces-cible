Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer, fields: [
    :uid,
    :email,
    :name,
    :siret,
    :organizational_unit
  ], uid_field: :uid if Rails.env.local?

  scope = "openid email given_name usual_name siret organizational_unit belonging_population"

  proconnect_options = Rails.application.credentials.dig(:proconnect, Rails.application.staging? ? :staging : Rails.env)
  provider :proconnect, proconnect_options.to_h.merge(scope:)
end

# Make Omniauth compatible with rack_csrf
OmniAuth::AuthenticityTokenProtection.default_options(key: "csrf.token", authenticity_param: "_csrf")
