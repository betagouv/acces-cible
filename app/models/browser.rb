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
    def fetch(url)
      instance.fetch(url)
    end
  end

  def fetch(url)
    page = browser.create_page
    pending_requests = {}

    # Setup network request tracking
    page.on(:request) do |request|
      pending_requests[request.id] = {
        url: request.url,
        resource_type: request.resource_type,
        started_at: Time.current
      }
      Rails.logger.debug { "Request started: #{request.id} - #{request.url} (#{request.resource_type})" }
    end

    page.on(:request_failed) do |request|
      Rails.logger.debug { "Request failed: #{request.id} - #{request.url} (#{request.resource_type})" }
      pending_requests.delete(request.id)
    end

    page.on(:response) do |response|
      if pending_requests[response.request.id]
        Rails.logger.debug { "Response received: #{response.request.id} - #{response.request.url} (#{response.status})" }
        pending_requests.delete(response.request.id)
      end
    end
    begin
      page.go_to(url)
      begin
        page.network.wait_for_idle(timeout: 2)
      rescue Ferrum::TimeoutError
        log_pending_requests(pending_requests, url)
        Rails.logger.warn { "Network idle timeout for #{url}, proceeding with current state" }
      end
      {
        body: page.body,
        status: page.network.status,
        headers: page.network.response&.headers || {},
        current_url: URI.parse(page.current_url)
      }
    rescue Ferrum::PendingConnectionsError
      log_pending_requests(pending_requests, url)
      Rails.logger.warn { "Pending connections for #{url}, proceeding with current state" }
      {
        body: page.body,
        status: page.network.status || 200,
        headers: page.network.response&.headers || {},
        current_url: URI.parse(page.current_url)
      }
    rescue Ferrum::Error => e
      Rails.logger.error { "Browser error fetching #{url}: #{e.message}" }
      raise e
    ensure
      page&.close # Prevent memory leaks
    end
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

  def log_pending_requests(pending_requests, url)
    if pending_requests.any?
      Rails.logger.error { "===== PENDING REQUESTS for #{url} =====" }
      pending_requests.each do |id, details|
        duration = Time.current - details[:started_at]
        Rails.logger.error { "  [#{id}] #{details[:url]} (#{details[:resource_type]}) - Pending for #{duration.round(2)}s" }
      end
      Rails.logger.error { "=====================================" }
    else
      Rails.logger.info { "No pending requests found for #{url}" }
    end
  end
end
