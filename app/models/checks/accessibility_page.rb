module Checks
  class AccessibilityPage < Check
    PRIORITY = 20

    store_accessor :data, :url, :title, :audit_date, :compliance_rate, :standard, :auditor

    private

    def found? = url.present?
    def custom_badge_text = found? ? human(:link_to, name: site&.name) : human(:not_found)
    def custom_badge_status = found? ? :success : :error
    def custom_badge_link = url
    def analyze! = Analyzers::AccessibilityPage.analyze(crawler)
  end
end
