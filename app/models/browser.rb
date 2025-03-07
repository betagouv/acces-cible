# Based on https://railsnotes.xyz/blog/ferrum-stealth-browsing

class Browser
  include Singleton

  PAGE_TIMEOUT = 5 # seconds
  PROCESS_TIMEOUT = 10 # seconds
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
      instance.fetch(url)
    end
  end

  def fetch(url)
    page = browser.create_page
    page.goto(url)
    {
      body: page.body,
      status: page.network.status,
      headers: page.network.response.headers,
      current_url: URI.parse(page.current_url)
    }
  rescue Ferrum::Error => e
    Rails.logger.error { "Browser error fetching #{url}: #{e.message}" }
    raise e
  end

  private

  def browser
    @browser ||= begin
      Ferrum::Browser.new(settings).tap do |browser|
        browser.headers.set(HEADERS)
        browser.network.intercept
        browser.on(:request) do |request|
          if request.url.end_with?(*BLOCKED_EXTENSIONS)
            request.abort
          else
            request.continue
          end
        end
        browser
      end
    end
  end

  def settings
    @settings ||= begin
      {
        headless: :new,
        timeout: PAGE_TIMEOUT,
        window_size: WINDOW_SIZE,
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

  def stub(request)
    uri = URI.parse(request.url)
    stub = WebMock::StubRegistry.instance.request_stubbed?(WebMock::RequestSignature.new(:get, uri))
    response = stub.response
    request.respond(
      status: response.status[0],
      headers: { "content-type" => "text/html" },
      body: response.body
    )
  end
end
