FactoryBot.define do
  factory :page_snapshot do
    audit { association :audit, :without_checks }
    kind { "home" }
    requested_url { "https://example.com" }
    current_url { "https://example.com/" }
    html { "<html><body></body></html>" }
    status { 200 }
    content_type { "text/html" }
  end
end
