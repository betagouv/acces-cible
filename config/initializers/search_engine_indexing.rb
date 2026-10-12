Rails.application.config.action_dispatch.default_headers["X-Robots-Tag"] = "noindex, nofollow" if Rails.application.staging?
