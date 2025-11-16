# frozen_string_literal: true

if Rails.env.test? && defined?(OmniAuth)
  module OmniAuth
    module Strategy
      def setup_phase
        return if OmniAuth.config.test_mode?

        super
      end
    end
  end
end
