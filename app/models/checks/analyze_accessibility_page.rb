module Checks
  class AnalyzeAccessibilityPage < Check
    PRIORITY = 21
    REQUIREMENTS = [:find_accessibility_page]

    AUDIT_DATE_PATTERN = /(?<full_date>(?:réalisé(?:e)?(?:\s+le)?|du|en|le)\s+(?:(?:(?<day>\d{1,2})(?:\s+|er\s+)?)?(?<month>[a-zéûà]+)\s+(?<year>\d{4})|(?<day_num>\d{1,2})[\/\-\.](?<month_num>\d{1,2})[\/\-\.](?<year_num>\d{4})))/i
    AUDIT_DATE_KEYWORDS = ["audit", "conformité", "accessibilité", "révèle", "finalisé", "réalisé"].freeze
    COMPLIANCE_PATTERN = /(?:(?:avec (?:un |une )?)?taux de conformité|conforme à|révèle que).*?(\d+(?:[.,]\d+)?)(?:\s*%| pour cent)/i
    STANDARD_PATTERN = /(?:au |des critères )?(?:(RGAA(?:[. ](?:version|v)?[. ]?\d+(?:\.\d+(?:\.\d+)?)?)?|(WCAG)))/i
    AUDITOR_PATTERN = /(?:par(?:\s+la)?(?:\s+société)?|par)\s+([^,]+?)(?:,| révèle| sur)/i

    LAW_DATE = Date.new(2005, 2, 11)

    store_accessor :data, :audit_date, :compliance_rate, :standard, :auditor

    def audit_date = super&.to_date

    def find_audit_date
      date_matches = page.text.scan(AUDIT_DATE_PATTERN).map do |full_date, day_str, month_str, year_str, day_num, month_num, year_num|
        begin
          if day_num && month_num && year_num
            day, month, year = day_num.to_i, month_num.to_i, year_num.to_i
          else
            day, month, year = (day_str || "1").to_i, month_names[month_str.downcase], year_str.to_i
          end
          date = Date.new(year, month, day)

          next if date == LAW_DATE || year < 2010

          score = 0
          score += 1 if year >= 2020
          position = page.text.index(full_date) || 0
          nearby_text = page.text[([position - 100, 0].max)..([position + 100, page.text.length].min)] || ""
          score += AUDIT_DATE_KEYWORDS.count { |kw| nearby_text.match?(/#{kw}/i) }
          [date, score]
        rescue Date::Error, NoMethodError
          nil
        end
      end.compact

      # Return the date with highest score, or nil if no valid dates found
      date_matches.max_by { |date, score| score }&.first
    end

    def find_compliance_rate
      return unless (match = page.text.match(COMPLIANCE_PATTERN))

      rate = match[1].tr(",", ".").to_f
      rate % 1 == 0 ? rate.to_i : rate
    end

    def find_standard
      page.text.scan(STANDARD_PATTERN).flatten.compact.sort_by(&:length).last
    end

    def find_auditor
      page.text.match(AUDITOR_PATTERN)&.[](1)&.strip
    end

    private

    def page = @page ||= Page.new(url: audit.find_accessibility_page.url) # TODO: Refactor to stop breaking the law of Demeter
    def found_required? = [:audit_date, :compliance_rate].all? { send(it).present? }
    def found_all? = found_required? && [:standard, :auditor].all? { send(it).present? }
    def custom_badge_status = found_required? ? :success : :warning
    def custom_badge_text = found_all? ? human(:found_all) : human(:missing_data)

    def analyze!
      {
        audit_date: find_audit_date,
        compliance_rate: find_compliance_rate,
        standard: find_standard,
        auditor: find_auditor
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
