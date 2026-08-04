# frozen_string_literal: true

class FetchHomePageService
  def initialize(audit)
    @audit = audit

    call
  end

  def call
    response = Browser.get(@audit.site.url)

    Rails.logger.silence do
      @audit.page_snapshots.find_or_create_by!(
        kind: "home",
        requested_url: @audit.site.url,
        current_url: response[:current_url],
        html: response[:body],
        status: response[:status],
        content_type: response[:content_type]
      )

      @audit.update!(home_page_url: response[:current_url])
    end
  end
end
