module EnvironmentExtensions
  def staging?
    Rails.env.production? && ENV["APP_URL"].to_s.match?("incubateur.net")
  end
end

Rails::Application.include(EnvironmentExtensions)
