# frozen_string_literal: true

class FetchHomePageService
  class << self
    def call(audit)
      Browser
        .get(audit.url)
        .then { |response| audit.update_home_page!(response[:body]) }
    end
  end
end
