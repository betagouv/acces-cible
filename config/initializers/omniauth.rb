Rails.application.config.middleware.use OmniAuth::Builder do
  if Rails.env.local?
    provider :developer, fields: [:uid], uid_field: :uid
  else
    proconnect = Rails.application.credentials.proconnect[Rails.application.staging? ? :staging : Rails.env]

    provider :proconnect,
      {
        client_id: proconnect.client_id,
        client_secret: proconnect.client_secret,
        proconnect_domain: proconnect.host,
        redirect_uri: "/auth/proconnect/callback",
        post_logout_redirect_uri: "/",
        scope: "openid email given_name usual_name siret organizational_unit belonging_population"
      }
    )
  end
end

# Make Omniauth compatible with rack_csrf
OmniAuth::AuthenticityTokenProtection.default_options(key: "csrf.token", authenticity_param: "_csrf")
