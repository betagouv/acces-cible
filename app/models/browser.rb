class Browser
  PAGE_TIMEOUT = 1.minute
  PROCESS_TIMEOUT = 30.seconds
  SUCCESS_CODE = 200

  REQUEST_HEADERS = {
    "Accept-Language" => "fr",
    "User-Agent" => "AccesCible/1.0 (+https://acces-cible.beta.gouv.fr/)"
  }.freeze

  BLOCKED_FILE_EXTENSIONS = %w[
    .woff .woff2 .ttf .otf .eot
    .mp4 .avi .mov .mkv .webm
    .mp3 .ogg .wav .aac .flac
    .jpg .jpeg .png .gif .bmp .svg .webp .avif
  ].freeze

  BLOCKED_FILE_PATTERN = Regexp.new(
    "(#{Regexp.union(BLOCKED_FILE_EXTENSIONS).source})(?:\\?.*|#.*)?$",
    Regexp::IGNORECASE
  )

  TRACKING_DOMAINS = [
    "google-analytics.com",
    "googletagmanager.com",
    "facebook.net",
    "facebook.com",
    "twitter.com",
    "linkedin.com",
    "doubleclick.net",
    "adservice.google.com",
    "youtube.com",
    "play.google.com",
    "sites.statistiques.online",
    "googleapis.com",
  ].freeze

  TRACKING_DOMAIN_PATTERN = Regexp.union(TRACKING_DOMAINS)
  BLOCKED_URL_PATTERNS = [BLOCKED_FILE_PATTERN, TRACKING_DOMAIN_PATTERN].freeze

  BROWSER_OPTIONS = {
    "disable-blink-features" => "AutomationControlled",
    "disable-dev-shm-usage" => nil,
    "disable-features" => "TranslateUI,VizDisplayCompositor",
    "disable-gpu" => nil,
    "no-sandbox" => nil
  }.freeze

  STEALTH_EXTENSION = Rails.root.join("vendor/javascript/stealth.min.js").freeze

  class << self
    def reachable?(url)
      url && head(url)[:status] == SUCCESS_CODE
    end

    def head(url)
      response = HTTP
        .headers(request_headers)
        .timeout(connect: 3, read: 3)
        .follow(max_hops: 3)
        .head(url, ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
      # Disable SSL because some websites provide CRLs via HTTP,
      # which OpenSSL ignores, throwing connection failure.
      # Harmless for head requests.

      {
        status: response.code || 0,
        current_url: Link.normalize(response.uri.to_s)
      }
    rescue
      {
        status: 0,
        current_url: Link.normalize(url)
      }
    end

    def request_headers
      REQUEST_HEADERS
    end

    def settings
      {
        headless: :new,
        timeout: PAGE_TIMEOUT,
        process_timeout: PROCESS_TIMEOUT,
        pending_connection_errors: false,
        extensions: [STEALTH_EXTENSION],
        browser_options: browser_options
      }.tap do |options|
        if Rails.env.production?
          chrome_path = ENV["GOOGLE_CHROME_SHIM"]

          options[:browser_path] = chrome_path if chrome_path.present?
        end
      end.freeze
    end

    def get(url)
      with_page do |page|
        page.go_to(url)
        page.network.wait_for_idle(timeout: PAGE_TIMEOUT)

        {
          body: page.body,
          status: page.network.status,
          content_type: page.network.response.content_type,
          current_url: Link.normalize(page.current_url)
        }
      end
    end

    def page_from_html(html)
      with_page do |page|
        page.content = html
        page.bypass_csp

        yield(page)
      end
    end

    def run_script_on_html(html, script, script_tag)
      page_from_html(html) do |page|
        page.add_script_tag(content: script_tag)

        page.evaluate_async(script, PAGE_TIMEOUT)
      end
    end

    private

    def browser
      @browser ||= Ferrum::Browser.new(settings)
    end

    def browser_options
      BROWSER_OPTIONS.merge(
        "user-data-dir" => user_data_dir,
      )
    end

    def user_data_dir
      @user_data_dir ||= "/tmp/chrome-#{SecureRandom.hex(8)}"
    end

    def with_page
      page = create_page
      yield(page)
    ensure
      page&.close
    end

    def create_page
      browser.create_page.tap do |page|
        page.headers.set(request_headers)
        block_unwanted_requests(page)
      end
    end

    def block_unwanted_requests(page)
      page.network.intercept(handle_auth_requests: false)
      page.on(:request) do |request|
        if blocked_request?(page, request)
          request.abort
        else
          request.continue
        end
      end
    end

    def blocked_request?(page, request)
      blocked_url?(request.url) || iframe_document_request?(page, request)
    end

    def blocked_url?(url)
      BLOCKED_URL_PATTERNS.any? { |pattern| url.to_s.match?(pattern) }
    end

    def iframe_document_request?(page, request)
      request.resource_type == "Document" && request.frame_id != page.main_frame.id
    end
  end
end
