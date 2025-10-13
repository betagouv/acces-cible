module Checks
  class AnalyzeAccessibilityPage < Check
    PRIORITY = 21
    REQUIREMENTS = Check::REQUIREMENTS + [:find_accessibility_page]

    ARTICLE = /(?:art(?:icle)?\.? 47|article 47) (?:de la )?loi (?:n[°˚]|num(?:éro)?\.?) ?2005-102 du 11 (?:février|fevrier) 2005/i
    AUDIT_DATE_PATTERN = /(?<full_date>(?:réalisé(?:e)?(?:\s+le)?|du|en|le)\s+(?:(?:(?<day>\d{1,2})(?:\s+|er\s+)?)?(?<month>[a-zéûà]+)\s+(?<year>\d{4})|(?<day_num>\d{1,2})[\/\-\.](?<month_num>\d{1,2})[\/\-\.](?<year_num>\d{4})))/i
    AUDIT_DATE_KEYWORDS = ["audit", "conformité", "accessibilité", "révèle", "finalisé", "réalisé"].freeze
    COMPLIANCE_PATTERN = /(?:(?:avec (?:un |une )?)?taux de conformité|conforme à|révèle que).*?(\d+(?:[.,]\d+)?)(?:\s*%| pour cent)/i
    STANDARD_PATTERN = /(?:au |des critères )?(?:(RGAA(?:[. ](?:version|v)?[. ]?\d+(?:\.\d+(?:\.\d+)?)?)?|(WCAG)))/i
    AUDITOR_PATTERN = /(?:par(?:\s+la)?(?:\s+société)?|par)\s+([^,]+?)(?:,| révèle| sur)/i
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

    store_accessor :data, :audit_date, :audit_update_date, :compliance_rate, :standard, :auditor, :mentions_article

    def tooltip? = !(completed? && found_required?)
    def audit_date = super&.to_date
    def audit_update_date = super&.to_date
    def human_compliance_rate = helpers.number_to_percentage(compliance_rate, precision: 2, strip_insignificant_zeros: true)

    def find_audit_date
      date_matches = page.text.scan(AUDIT_DATE_PATTERN).map do |full_date, day_str, month_str, year_str, day_num, month_num, year_num|
        next if (year_str&.to_i || year_num&.to_i || 2000) > Date.current.year

        begin
          if day_num && month_num && year_num
            day, month, year = day_num.to_i, month_num.to_i, year_num.to_i
          else
            day, month, year = (day_str || 1).to_i, month_names[month_str.downcase], year_str.to_i
          end
          date = Date.new(year, month, day)

          next if date == LAW_DATE || year < 2010

          score = 0
          score += 1 if year >= 2020
          position = page.text.index(full_date) || 0
          nearby_text = page.text[([position - 100, 0].max)..([position + 100, page.text.length].min)] || ""
          score += AUDIT_DATE_KEYWORDS.count { |kw| nearby_text.match?(/#{kw}/i) }
          [date, score]
        rescue Date::Error, NoMethodError, TypeError
          nil
        end
      end.compact

      # Return the date with highest score, or nil if no valid dates found
      date_matches.max_by { |date, score| score }&.first
    end

    def find_audit_update_date
      return unless audit_date

      date_matches = []
      UPDATE_AUDIT_PATTERNS.each do |pattern|
        page.text.scan(pattern).each do |day_str, month_str, year_str, day_num, month_num, year_num|
          next if (year_str&.to_i || year_num&.to_i || 2000) > Date.current.year

          begin
            if day_num && month_num && year_num
              day, month, year = day_num.to_i, month_num.to_i, year_num.to_i
            else
              day, month, year = (day_str || 1).to_i, month_names[month_str.downcase], year_str.to_i
            end
            date = Date.new(year, month, day)
            next if date < audit_date || year < 2010

            score = 0
            score += 1 if year >= audit_date.year + 3.years
            date_str = day_num ? "#{day_num}/#{month_num}/#{year_num}" : "#{day_str} #{month_str} #{year_str}"
            position = page.text.index(date_str) || 0
            nearby_text = page.text[([position - 150, 0].max)..([position + 150, page.text.length].min)] || ""
            UPDATE_AUDIT_KEYWORDS.each { |keyword| score += 1 if nearby_text.match?(/#{Regexp.escape(keyword)}/i) }
            next if score.zero?

            date_matches << [date, score]
          rescue Date::Error, NoMethodError, TypeError
            nil
          end
        end
      end

      date_matches.max_by { |date, score| [date, score] }&.first
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
      match = page.text.match(AUDITOR_PATTERN)&.[](1)&.strip
      match if match && match.split.size <= 4 # Names longer than 4 words are probably false positives
    end

    def find_article_mention = page.text.match?(ARTICLE)

    def custom_badge_status = found_required? ? :success : :warning
    def custom_badge_text = found_required? ? human_compliance_rate : human(:missing_data)

    private

    def page = @page ||= Page.new(url: audit.find_accessibility_page.url) # TODO: Refactor to stop breaking the law of Demeter
    def found_required? = [:audit_date, :compliance_rate, :mentions_article].all? { send(it).present? }
    def found_all? = found_required? && [:standard, :auditor].all? { send(it).present? }

    def analyze!
      return unless audit.find_accessibility_page&.url

      {
        audit_date: find_audit_date,
        audit_update_date: find_audit_update_date,
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
