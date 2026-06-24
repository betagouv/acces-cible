class Browser
  PAGE_TIMEOUT = 1.minute
  PROCESS_TIMEOUT = 30.seconds
  SUCCESS_CODE = 200

  REQUEST_HEADERS = {
    "Accept-Language" => "fr"
  }.freeze

  DOCUMENT_EXTENSIONS = [
    # PDF and archives
    %w[.pdf .zip],
    # OpenDocument and Microsoft Office
    %w[.odt .ods .odp .odg .doc .docx .xls .xlsx .ppt .pptx],
    # Text, data, and Apple iWork
    %w[.rtf .txt .csv .tsv .pages .numbers],
  ].flatten.freeze

  FILE_EXTENSIONS = [
    # Fonts
    %w[.woff .woff2 .ttf .otf .eot],
    # Feeds, structured data, calendars, icons, and cursors
    %w[.xml .rss .atom .ics .ical .ico .cur],
    # Images
    %w[.jpg .jpeg .png .gif .bmp .svg .webp .avif .tif .tiff .apng .heic .heif],
    # Audio and video
    %w[.mp3 .mp4 .avi .mov .mkv .webm .ogg .wav .aac .flac .m4a .opus],
    %w[.ogv .m4v .mpg .mpeg],
  ].flatten.freeze

  BLOCKED_FILE_EXTENSIONS = (FILE_EXTENSIONS + DOCUMENT_EXTENSIONS).freeze

  BLOCKED_FILE_PATTERN = Regexp.new(
    "(#{Regexp.union(BLOCKED_FILE_EXTENSIONS).source})(?:\\?.*|#.*)?$",
    Regexp::IGNORECASE
  )

  TRACKING_DOMAINS = [
    "google-analytics.com",
    "googletagmanager.com",
    /facebook\.(?:com|net)/i,
    "twitter.com",
    "linkedin.com",
    "doubleclick.net",
    "adservice.google.com",
    "googleadservices.com",
    "googlesyndication.com",
    "youtube.com",
    "play.google.com",
    "sites.statistiques.online",
    "googleapis.com",
    /hotjar\.(?:com|io)/i,
    "clarity.ms",
    "segment.io",
    "amplitude.com",
    "mixpanel.com",
    "matomo.cloud",
    "plausible.io",
    "fullstory.com",
    /intercom(?:\.io|cdn\.com)/i,
    /(?:nr-data\.net|newrelic\.com)/i,
    /(?:browser-intake-datadoghq|datadoghq-browser-agent)\.com/i,
    "bugsnag.com",
    "rollbar.com",
    /sentry(?:\.[a-z0-9-]+)+/i,
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
        page.network.blocklist = BLOCKED_URL_PATTERNS
      end
    end
  end
end
