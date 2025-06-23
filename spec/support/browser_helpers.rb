module BrowserHelpers
  def mock_browser(
      url: "https://example.com/",
      status: 200,
      headers: { "Content-Type" => "text/html" },
      body: "<html><head><title>Test</title></head><body><h1>Test</h1></body></html>"
    )
    mocked_browser = instance_double(Browser)
    allow(Browser).to receive(:new).and_return(mocked_browser)
    allow(mocked_browser).to receive(:quit)
    allow(mocked_browser).to receive(:get).and_return({
      current_url: url,
      status:,
      headers:,
      body:
    })
    mocked_browser
  end
end

RSpec.configure do |config|
  config.include BrowserHelpers
end
