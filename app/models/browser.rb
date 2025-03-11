# Based on https://railsnotes.xyz/blog/ferrum-stealth-browsing

class Browser
  include Singleton

  PAGE_TIMEOUT = 5 # seconds
  PROCESS_TIMEOUT = 10 # seconds
  WINDOW_SIZES = [
    [1366, 768],
    [1440, 900],
    [1280, 800],
    [1920, 1080]
  ].freeze
  CHROME_VERSIONS = (101..134).to_a.freeze
  MACOS_VERSIONS = ["10_15_7", "13_4_1", "13_6_6", "14_1_2", "14_7_1", "14_7_3", "15_1_1"].freeze

  HEADERS = {
    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Accept-Encoding" => "gzip, deflate, br, zstd",
    "Accept-Language" => "fr-FR,en-US;q=0.9,en;q=0.8",
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
    FONTS = [".woff", ".woff2", ".ttf", ".otf", ".eot"].freeze,
    VIDEOS = [".mp4", ".avi", ".mov", ".mkv", ".webm"].freeze,
    AUDIO = [".mp3", ".ogg", ".wav", ".aac", ".flac"].freeze,
    IMAGES = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".svg", ".webp", ".avif"].freeze
  ].flatten.freeze

  BLOCKED_DOMAINS = [
    "google-analytics.com",
    "googletagmanager.com",
    "facebook.net",
    "facebook.com",
    "twitter.com",
    "linkedin.com",
    "doubleclick.net",
    "adservice.google.com"
  ].freeze

  class << self
    def get(url)
      instance.get(url)
    end
  end

  def get(url)
    page = browser.create_page
    begin
      page.network.wait_for_idle(timeout: 2)
      begin
        page.go_to(url)
      rescue Ferrum::TimeoutError, Ferrum::PendingConnectionsError
        Rails.logger.warn { "Network idle timeout for #{url}, proceeding with current state" }
      end
      {
        body: page.body,
        status: page.network.status || 200,
        headers: page.network.response&.headers || {},
        current_url: URI.parse(page.current_url)
      }
    end
    rescue Ferrum::Error => ferrum_error
      Rails.logger.error { "Browser error fetching #{url}: #{ferrum_error.message}" }
      raise ferrum_error
    ensure
      reset
    end
  end

  private

  def browser
    @browser ||= begin
      Ferrum::Browser.new(settings).tap do |browser|
        browser.headers.set(HEADERS)
        browser.headers.add(random_user_agent)
        browser.network.intercept
        browser.on(:request) do |request|
          if request.url.end_with?(*BLOCKED_EXTENSIONS)
            request.abort
          elsif BLOCKED_DOMAINS.any? { |domain| request.url.include?(domain) }
            request.abort
          else
            request.continue
          end
        end
        browser
      end
    end
  end

  def reset
    browser&.reset
    browser&.quit
    @browser = nil
  end

  def settings
    @settings ||= begin
      {
        headless: :new,
        timeout: PAGE_TIMEOUT,
        window_size: WINDOW_SIZES.sample,
        process_timeout: PROCESS_TIMEOUT,
        extensions: [Rails.root.join("vendor/javascript/stealth.min.js")],
        browser_options: {
          "disable-blink-features": "AutomationControlled",
          "disable-popup-blocking": true,
          "disable-notifications": true
        }
      }.tap do |options|
        options[:browser_path] = ENV["GOOGLE_CHROME_SHIM"] if Rails.env.production?
        options[:proxy] = Rails.application.credentials.proxy if Rails.env.production?
      end.freeze
    end
  end

  def random_user_agent
    macos_version = MACOS_VERSIONS.sample
    chrome_version = CHROME_VERSIONS.sample
    {
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X #{macos_version}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/#{chrome_version}.0.0.0 Safari/537.36",
      "Sec-Ch-Ua" => "\"Google Chrome\";v=\"#{chrome_version}\", \"Chromium\";v=\"#{chrome_version}\", \"Not_A Brand\";v=\"24\"",
    }
  end
end
