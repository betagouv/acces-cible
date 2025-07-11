# frozen_string_literal: true

# shortcut all auth requests
OmniAuth.config.test_mode = true

# reset potential mocks after each test
After do
  OmniAuth.config.mock_auth[:proconnect] = nil
end
