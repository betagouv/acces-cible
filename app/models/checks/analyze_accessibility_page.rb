module Checks
  class AnalyzeAccessibilityPage < Check
    PRIORITY = 21
    REQUIREMENTS = Check::REQUIREMENTS + [:find_accessibility_page]

    ARTICLE = /(?:art(?:icle)?\.? 47|article 47) (?:de la )?loi (?:n[°˚]|num(?:éro)?\.?) ?2005-102 du 11 (?:février|fevrier) 2005/i
    AUDIT_DATE_PATTERN = /(?<full_date>(?:réalisé(?:e)?(?:\s+le)?|établi(?:e)?(?:\s+le)?|en|du|le|au)\s+(?:(?:(?<day>\d{1,2})(?:\s+|er\s+)?)?(?<month>[a-zéûà]+)\s+(?<year>\d{4})|(?<day_num>\d{1,2})[\/\-\.](?<month_num>\d{1,2})[\/\-\.](?<year_num>\d{4})))/i
    AUDIT_UPDATE_DATE_PATTERN = /(?<full_date>(?:mis(?:e)?\s+à\s+jour(?:\s+le)?|actualisé(?:e)?(?:\s+le)?|modifié(?:e)?(?:\s+le)?)\s+(?:(?:(?<day>\d{1,2})(?:\s+|er\s+)?)?(?<month>[a-zéûà]+)\s+(?<year>\d{4})|(?<day_num>\d{1,2})[\/\-\.](?<month_num>\d{1,2})[\/\-\.](?<year_num>\d{4})))/i
    AUDIT_DATE_KEYWORDS = ["audit", "conformité", "accessibilité", "révèle", "finalisé", "réalisé"].freeze
    COMPLIANCE_PATTERN = /(?:(?:avec (?:un |une )?)?taux de conformité (?!moyen)|conforme à|révèle que|des critères)[^.]*?(\d+(?:[.,]\d+)?)(?:\s*%| pour cent)|(\d{1,2}(?:[.,]\d+)?)\s*%\s*(?:des critères(?: RGAA)?|au RGAA)/i
    STANDARD_PATTERN = /(?:au |des critères )?(?:(RGAA(?:[. ](?:version|v)?[. ]?\d+(?:\.\d+(?:\.\d+)?)?)?|(WCAG)))/i
    AUDITOR_PATTERN = /(?:réalisé(?:e)?\s+par|par|l[’']\s*agence|la\s+société)\s+(?:la\s+société\s+|l[’']\s*agence\s+)?([^,.]+?)(?:,| révèle| sur|\.|$)/i
    UPDATE_AUDIT_PATTERNS = [
      /Au\s+(?:(\d{1,2})(?:\s+|er\s+)?)?([a-zéûà]+)\s+(\d{4}).*(?:indique|mentionne).*(?:depuis|après).*(?:précédent|dernier)\s+audit/i,
      /Suite\s+à.*(?:réalisé(?:e)?(?:\s+le)?|du|en|le)\s+(?:(?:(\d{1,2})(?:\s+|er\s+)?)?([a-zéûà]+)\s+(\d{4})|(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})).*(?:dorénavant|désormais|maintenant|actuellement)/i,
      /(?:(?:(\d{1,2})(?:\s+|er\s+)?)?([a-zéûà]+)\s+(\d{4})|(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4}))/i
    ].freeze
    UPDATE_AUDIT_KEYWORDS = [
      "suite à", "actualisation", "actualisé", "mis à jour", "mise à jour", "modification",
      "revu", "révisé", "révision", "réévaluation", "nouvelle évaluation",
      "dorénavant", "désormais", "maintenant", "actuellement", "inchangé",
    ].freeze

    LAW_DATE = Date.new(2005, 2, 11)
    HEADERS_SCOPE = ["Établissement de cette déclaration d’accessibilité", "État de conformité", "Déclaration d’accessibilité", "Résultats des tests"]

    store_accessor :data, :audit_date, :audit_update_date, :compliance_rate, :standard, :auditor, :mentions_article

    def tooltip?
      !(completed? && found_required?)
    end

    def audit_date
      super&.to_date
    end

    def audit_update_date
      super&.to_date
    end

    def human_compliance_rate
      to_percent(compliance_rate)
    end

    def extract_date(text)
      return nil if text.blank?

      text.each do |_, day_str, month_str, year_str, day_num, month_num, year_num|
        day = (day_num.presence || day_str.presence)&.to_i
        day = 1 if day.nil? || day == 0
        month = (month_num.presence && month_num.to_i) || (month_str.present? && month_names[month_str.downcase])
        year = (year_num.presence || year_str.presence)&.to_i

        date = Date.new(year, month, day) rescue nil

        next if date == LAW_DATE
        next if date && date.year > Time.now.year

        return date
      end

      nil
    end

    def find_audit_date(pattern)
      extracted_text = []

      HEADERS_SCOPE.each do |header_scope|
        extracted_text << page.text(between_headings: [header_scope, :next])
      end

      extracted_text << page.text(between_headings: [:previous, "État de conformité"])

      extracted_text = extracted_text.compact.join(" ")
      matches = extracted_text.scan(pattern)

      return nil if matches.blank?

      extract_date(matches)
    end

    def find_compliance_rate
      test_results_section = page.text(between_headings: ["Résultats des tests", :next])
      matches = test_results_section.scan(COMPLIANCE_PATTERN)

      return if matches.empty?

      most_recent_match = matches.last
      rate_string = most_recent_match.compact.first
      rate = rate_string.tr(",", ".").to_f

      rate % 1 == 0 ? rate.to_i : rate
    end

    def find_standard
      page.text.scan(STANDARD_PATTERN).flatten.compact.sort_by(&:length).last
    end

    def find_auditor
      test_results_section = page.text(between_headings: ["Résultats des tests", :next])

      match = test_results_section.match(AUDITOR_PATTERN)&.[](1)&.strip
      match if match && match.split.size <= 4 # Names longer than 4 words are probably false positives
    end

    def find_article_mention
      page.text.match?(ARTICLE)
    end

    def custom_badge_status
      found_required? ? :success : :warning
    end

    def custom_badge_text
      found_required? ? human_compliance_rate : human(:missing_data)
    end

    private

    def page
      @page ||= audit.page(:accessibility)
    end

    def found_required?
      [:audit_date, :compliance_rate, :mentions_article].all? { send(it).present? }
    end

    def found_all?
      found_required? && [:standard, :auditor].all? { send(it).present? }
    end

    def analyze!
      return unless page

      {
        audit_date: find_audit_date(AUDIT_DATE_PATTERN),
        audit_update_date: find_audit_date(AUDIT_UPDATE_DATE_PATTERN),
        compliance_rate: find_compliance_rate,
        standard: find_standard,
        auditor: find_auditor,
        mentions_article: find_article_mention
      }
    end

    def month_names
      @month_names ||= begin
        names = I18n.t("date.month_names")[1..] + I18n.t("date.abbr_month_names")[1..]
        names.each_with_object({}) do |name, hash|
          next if name.blank?

          normalized = name.downcase.tr("éû", "eu")
          hash[name.downcase] = names.index(name) % 12 + 1
          hash[normalized] = names.index(name) % 12 + 1
        end
      end
    end
  end
end
