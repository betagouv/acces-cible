class SiteCsvExport < CsvExport
  def attributes
    {
      Audit.human(:url) => :url,
      Tag.human(:all) => :tags_list,
      Check.human(:checked_at) => [:audit, :checked_at],
      Checks::Reachable.human(:type) => [:audit, :reachable, :completed?],
      Checks::LanguageIndication.human(:type) => [:audit, :language_indication, :indication],
      Checks::AccessibilityMention.human(:type) => [:audit, :accessibility_mention, :mention_text],
      Checks::FindAccessibilityPage.human(:type) => [:audit, :find_accessibility_page, :url],
      Checks::AnalyzeAccessibilityPage.human(:compliance_rate) => [:audit, :analyze_accessibility_page, :human_compliance_rate],
      Checks::AnalyzeAccessibilityPage.human(:audit_date) => [:audit, :analyze_accessibility_page, :audit_date],
      Checks::AnalyzeAccessibilityPage.human(:audit_update_date) => [:audit, :analyze_accessibility_page, :audit_update_date],
      Checks::AccessibilityPageHeading.human(:type) => [:audit, :accessibility_page_heading, :human_success_rate],
      Checks::RunAxeOnHomepage.human(:success_rate) => [:audit, :run_axe_on_homepage, :human_success_rate],
    }
  end
end
