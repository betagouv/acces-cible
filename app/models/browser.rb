# Based on https://railsnotes.xyz/blog/ferrum-stealth-browsing

class Browser
  include Singleton

  TIMEOUT = 5 # seconds
  WINDOW_SIZE = [1366, 768] # width, height

  HEADERS = {
    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Accept-Encoding" => "gzip, deflate, br, zstd",
    "Accept-Language" => "fr-FR,en-US;q=0.9,en;q=0.8",
    "Cache-Control" => "no-cache",
    "Pragma" => "no-cache",
    "Priority" => "u=0, i",
    "Sec-Ch-Ua" => '"Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
    "Sec-Ch-Ua-Mobile" => "?0",
    "Sec-Ch-Ua-Platform" => "\"macOS\"",
    "Sec-Fetch-Dest" => "document",
    "Sec-Fetch-Mode" => "navigate",
    "Sec-Fetch-Site" => "cross-site",
    "Sec-Fetch-User" => "?1",
    "Upgrade-Insecure-Requests" => "1",
    "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
  }.freeze

  BLOCKED_EXTENSIONS = [
    FONTS = [".woff", ".woff2", ".ttf", ".otf", ".eot"].freeze,
    VIDEOS = [".mp4", ".avi", ".mov", ".mkv", ".webm"].freeze,
    AUDIO = [".mp3", ".ogg", ".wav", ".aac", ".flac"].freeze,
    IMAGES = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".svg", ".webp", ".avif"].freeze
  ].flatten.freeze

  class << self
    def fetch(url)
      page = instance.send(:browser).create_page
      page.go_to(url)
      page
    end
  end

  def kill
    @browser = nil
  end

  private

  def browser
    @browser ||= begin
      Ferrum::Browser.new(settings).tap do |browser|
        browser.headers.set(HEADERS)
        # Skip resources to preserve bandwidth
        browser.network.intercept
        browser.on(:request) do |request|
          request.url.end_with?(*BLOCKED_EXTENSIONS) ? request.abort : request.continue
        end
      end
    end
  end

  def settings
    @settings ||= begin
      {
        headless: :new,
        timeout: TIMEOUT,
        window_size: WINDOW_SIZE,
        extensions: [Rails.root.join("vendor/javascript/stealth.min.js")],
        browser_options: { "disable-blink-features": "AutomationControlled" }
      }.tap do |options|
        options[:browser_path] = browser_path if Rails.env.production?
        options[:proxy] = Rails.application.credentials.proxy if Rails.env.production?
      end.freeze
    end
  end

  def browser_path = ENV["GOOGLE_CHROME_BIN"]
end
