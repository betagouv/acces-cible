# frozen_string_literal: true

class FetchHomePageService
  class << self
    def call(audit)
      Browser
        .get(audit.url)
        .then do |response|
        Rails.logger.silence do
          audit.update_home_page!(response[:current_url], response[:body])
        end
      end
    end
  end
end
