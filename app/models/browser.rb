# Based on https://railsnotes.xyz/blog/ferrum-stealth-browsing

class Browser
  PAGE_TIMEOUT = 1.minute
  PROCESS_TIMEOUT = 30.seconds
  WINDOW_SIZES = [
    [1366, 768],
    [1440, 900],
    [1280, 800],
    [1920, 1080]
  ].freeze
  SUCCESS_CODE = 200
  CHROME_VERSIONS = (101..134).to_a.freeze
  MACOS_VERSIONS = %w[10_15_7 13_4_1 13_6_6 14_1_2 14_7_1 14_7_3 15_1_1].freeze

  HEADERS = {
    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Accept-Encoding" => "gzip, deflate, br, zstd",
    "Accept-Language" => "fr;q=1",
    "Cache-Control" => "no-cache",
    "Pragma" => "no-cache",
    "Priority" => "u=0, i",
    "Sec-Ch-Ua-Mobile" => "?0",
    "Sec-Fetch-Dest" => "document",
    "Sec-Fetch-Mode" => "navigate",
    "Sec-Fetch-Site" => "cross-site",
    "Sec-Fetch-User" => "?1",
    "Sec-Ch-Ua-Platform" => "\"macOS\"",
    "Upgrade-Insecure-Requests" => "1",
  }.freeze

  BLOCKED_EXTENSIONS = [
    FONTS = %w[.woff .woff2 .ttf .otf .eot],
    VIDEOS = %w[.mp4 .avi .mov .mkv .webm],
    AUDIO = %w[.mp3 .ogg .wav .aac .flac],
    IMAGES = %w[.jpg .jpeg .png .gif .bmp .svg .webp .avif]
  ].flatten.then { |extensions| Regexp.new("(#{Regexp.union(extensions).source})(?:\\?.*|#.*)?$") }

  BLOCKED_DOMAINS = %w[
    google-analytics.com
    googletagmanager.com
    facebook.net
    facebook.com
    twitter.com
    linkedin.com
    doubleclick.net
    adservice.google.com
    youtube.com play.google.com
    sites.statistiques.online
    googleapis.com
  ].then { |domains| Regexp.union(domains) }

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
    rescue => e
      {
        status: 0,
        current_url: Link.normalize(url)
      }
    end

    def request_headers
      HEADERS.merge(random_user_agent)
    end

    def random_user_agent
      macos_version = MACOS_VERSIONS.sample
      chrome_version = CHROME_VERSIONS.sample
      {
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X #{macos_version}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/#{chrome_version}.0.0.0 Safari/537.36",
        "Sec-Ch-Ua" => "\"Google Chrome\";v=\"#{chrome_version}\", \"Chromium\";v=\"#{chrome_version}\", \"Not_A Brand\";v=\"24\"",
      }
    end

    def settings
      @settings ||= begin
        {
          headless: :new,
          timeout: PAGE_TIMEOUT,
          window_size: WINDOW_SIZES.sample,
          process_timeout: PROCESS_TIMEOUT,
          pending_connection_errors: false,
          extensions: [Rails.root.join("vendor/javascript/stealth.min.js")],
          browser_options: {
            "disable-blink-features": "AutomationControlled",
            "disable-popup-blocking": true,
            "disable-notifications": true,
            "no-sandbox" => nil,
            "disable-gpu" => nil,
            "disable-dev-shm-usage" => nil,
            "disable-background-timer-throttling" => nil,
            "disable-backgrounding-occluded-windows" => nil,
            "disable-renderer-backgrounding" => nil,
            "disable-features" => "TranslateUI,VizDisplayCompositor",
            "disable-extensions" => nil,
            "disable-plugins" => nil,
            "disable-default-apps" => nil,
            "user-data-dir" => (@user_data_dir = "/tmp/chrome-#{SecureRandom.hex(8)}"),
            "remote-debugging-port" => (9222 + Random.rand(1000)).to_s
          }
        }.tap do |options|
          options[:browser_path] = ENV["GOOGLE_CHROME_SHIM"] if Rails.env.production?
          options[:proxy] = Rails.application.credentials.proxy if Rails.env.production?
          options[:browser_options].merge!("no-sandbox" => nil) if ENV["WITHIN_DOCKER"].present?
        end.freeze
      end
    end

    def get(url)
      with_page do |page|
        page.go_to(url)
        sleep 0.5
        page.network.wait_for_idle(timeout: PAGE_TIMEOUT.to_f)
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

    def with_page
      begin
        page = create_page
        yield(page)
      ensure
        page&.close
      end
    end

    def create_page
      browser.create_page.tap do |page|
        page.headers.set(request_headers)
        page.network.blacklist = [BLOCKED_EXTENSIONS, BLOCKED_DOMAINS]
      end
    end
  end
end
