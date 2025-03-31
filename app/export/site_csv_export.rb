class SiteCsvExport < ApplicationExport
  EXTENSION = "csv"

  def to_csv
    CSV.generate(headers: true, col_sep: ";") do |csv|
      csv << attributes.keys
      records.each do |record|
        csv << serialize(record)
      end
    end
  end

  def attributes
    {
      human(:url) => :url,
      Check.human(:checked_at) => [:audit, :checked_at],
      Checks::Reachable.human(:type) => [:audit, :reachable, :passed?],
      Checks::LanguageIndication.human(:type) => [:audit, :language_indication, :indication],
      Checks::AccessibilityMention.human(:type) => [:audit, :accessibility_mention, :mention_text],
      Checks::FindAccessibilityPage.human(:type) => [:audit, :find_accessibility_page, :url],
      Checks::AnalyzeAccessibilityPage.human(:compliance_rate) => [:audit, :analyze_accessibility_page, :human_compliance_rate],
      Checks::AnalyzeAccessibilityPage.human(:audit_date) => [:audit, :analyze_accessibility_page, :audit_date],
      Checks::AnalyzeAccessibilityPage.human(:audit_update_date) => [:audit, :analyze_accessibility_page, :audit_update_date],
      Checks::RunAxeOnHomepage.human(:success_rate) => [:audit, :run_axe_on_homepage, :human_success_rate],
    }
  end

  def headers = attributes.keys

  def serialize(record)
    attributes.values.map do |methods|
      # Turns [:a, :b, :c] into record.a&.b&.c
      Array.wrap(methods).reduce(record) { |obj, method| obj&.public_send(method) }
    end
  end
end
