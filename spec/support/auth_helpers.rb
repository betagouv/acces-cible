module AuthHelpers
  def login_as(user)
    session = Current.session = user.sessions.create!
    allow_any_instance_of(Current).to receive(:session).and_return(session) # rubocop:disable RSpec/AnyInstance
  end

  # For system/feature specs
  def feature_login_as(user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:developer] = OmniAuth::AuthHash.new(
      provider: user.provider,
      uid: user.uid,
      info: {
        email: user.email,
        name: user.name,
        organizational_unit: user.team.organizational_unit
      },
      extra: {
        raw_info: { siret: user.team.siret }
      }
    )

    get "/auth/developer/callback"
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :feature
  config.include AuthHelpers, type: :request
  config.include AuthHelpers, type: :system

  OmniAuth.config.logger = Logger.new(IO::NULL)
  OmniAuth.config.silence_get_warning = true

  # Set up OmniAuth test mode globally
  config.before(:all) do
    OmniAuth.config.test_mode = true
    OmniAuth.config.request_validation_phase = nil
  end
end
