# Based on https://railsnotes.xyz/blog/ferrum-stealth-browsing

class Browser
  PAGE_TIMEOUT = 30.seconds
  PROCESS_TIMEOUT = 3.minutes
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
    FONTS = [".woff", ".woff2", ".ttf", ".otf", ".eot"],
    VIDEOS = [".mp4", ".avi", ".mov", ".mkv", ".webm"],
    AUDIO = [".mp3", ".ogg", ".wav", ".aac", ".flac"],
    IMAGES = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".svg", ".webp", ".avif"]
  ].flatten.then { |extensions| Regexp.new("(#{Regexp.union(extensions).source})(?:\\?.*|#.*)?$") }

  BLOCKED_DOMAINS = [
    "google-analytics.com",
    "googletagmanager.com",
    "facebook.net",
    "facebook.com",
    "twitter.com",
    "linkedin.com",
    "doubleclick.net",
    "adservice.google.com"
  ].then { |domains| Regexp.union(domains) }

  AXE_SOURCE_PATH = Rails.root.join("vendor/javascript/axe.min.js").freeze
  AXE_LOCALE_PATH = Rails.root.join("vendor/javascript/axe.fr.json").freeze

  class << self
    delegate_missing_to :new
  end

  attr_reader :browser

  def initialize
    @browser = Ferrum::Browser.new(settings).tap do |browser|
      browser.network.blocklist = [BLOCKED_EXTENSIONS, BLOCKED_DOMAINS]
    end
  end

  def get(url)
    with_page do |page|
      page.go_to(url)
      {
        body: page.body,
        status: page.network.status || 200,
        headers: page.network.response&.headers || {},
        current_url: Link.normalize(page.current_url)
      }
    end
  end

  def axe_check(url)
    with_page do |page|
      page.bypass_csp
      page.go_to(url)
      page.add_script_tag(content: File.read(AXE_SOURCE_PATH))
      locale = File.read(AXE_LOCALE_PATH)
      page.evaluate_async(<<~JS, PAGE_TIMEOUT)
        axe.configure({locale: #{locale} })
        axe.run(document, { standards: "wcag2aa", reporter: "v2"}).then(results => __f(results))
      JS
    end
  end

  def restart!
    cleanup_browser
    @browser = nil
  end

  private

  def with_page
    page = nil
    begin
      page = create_page
      yield(page)
    rescue Ferrum::TimeoutError, Ferrum::PendingConnectionsError, Ferrum::DeadBrowserError => error
      Rails.logger.warn { "[#{error.class.name}] Restarting browser" }
      restart!
      retry
    rescue Ferrum::Error => error
      Rails.logger.error { "Browser error: #{error.message}" }
      raise error
    ensure
      page&.close
      cleanup_browser
    end
  end

  def create_page
    browser.create_page.tap do |page|
      page.headers.set(HEADERS)
      page.headers.add(random_user_agent)
      page.network.wait_for_idle(timeout: PAGE_TIMEOUT)
    end
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
          "user-data-dir" => (@user_data_dir = "/tmp/chrome-#{SecureRandom.hex(8)}")
        }
      }.tap do |options|
        options[:browser_path] = ENV["GOOGLE_CHROME_SHIM"] if Rails.env.production?
        options[:proxy] = Rails.application.credentials.proxy if Rails.env.production?
        options[:browser_options].merge!("no-sandbox" => nil) if ENV["WITHIN_DOCKER"].present?
      end.freeze
    end
  end

  def cleanup_browser
    if browser
      browser.reset
      browser.close
      browser.quit
    end
  rescue => error
    Rails.logger.warn { "Error during browser cleanup: #{error.message}" }
  ensure
    cleanup_user_data_dir
  end

  def cleanup_user_data_dir
    FileUtils.rm_rf(@user_data_dir) if @user_data_dir && Dir.exist?(@user_data_dir)
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
