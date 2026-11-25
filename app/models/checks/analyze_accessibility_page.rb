module Checks
  class AnalyzeAccessibilityPage < Check
    PRIORITY = 21
    REQUIREMENTS = Check::REQUIREMENTS + [:find_accessibility_page]

    LAW_NUMBER = "2005-102".freeze
    AUDIT_DATE_PATTERN = /(?<full_date>(?:réalisé(?:e)?(?:\s+le)?|établi(?:e)?(?:\s+le)?|en|du|le|au)\s+(?:(?:(?<day>\d{1,2})(?:\s+|er\s+)?)?(?<month>[a-zéûà]+)\s+(?<year>\d{4})|(?<day_num>\d{1,2})[\/\-\.](?<month_num>\d{1,2})[\/\-\.](?<year_num>\d{4})))/i
    AUDIT_UPDATE_DATE_PATTERN = /(?<full_date>(?:mis(?:e)?\s+à\s+jour(?:\s+le)?|actualisé(?:e)?(?:\s+le)?|modifié(?:e)?(?:\s+le)?)\s+(?:(?:(?<day>\d{1,2})(?:\s+|er\s+)?)?(?<month>[a-zéûà]+)\s+(?<year>\d{4})|(?<day_num>\d{1,2})[\/\-\.](?<month_num>\d{1,2})[\/\-\.](?<year_num>\d{4})))/i
    COMPLIANCE_PATTERN = /(?:(?:avec (?:un |une )?)?taux (?:global )?de conformité |conforme à|révèle que|mis(?:e)? à jour à|des crit(?:è|e)res)(?:(?!\bmoyen\b)[^.])*?(\d+(?:[.,]\d+)?)(?:\s*%| pour cent)|(\d{1,3}(?:[.,]\d+)?)\s*%\s*(?:des crit(?:è|e)res(?: RGAA)?(?:\s+sont\s+respect(?:é|e)s)?|au RGAA)/i
    STANDARD_PATTERN = /(?:au |des critères )?(?:(RGAA(?:[. ](?:version|v)?[. ]?\d+(?:\.\d+(?:\.\d+)?)?)?|(WCAG)))/i
    AUDITOR_NAME_START = /(?:réalisée?|réalisation)[^.]*?\s+par\s+(?:la\s+société\s+|l[’']\s*agence\s+|la\s+|le\s+|l[’']\s*)?|la\s+société\s+|l[’']\s*agence\s+/i
    AUDITOR_NAME_END = /(?:,| révèle| sur|\.|$|\s(?:le|en)\s+(?:\d|[a-zéûà]+\s+\d{4}))/i
    AUDITOR_PATTERN = /(?:#{AUDITOR_NAME_START})([^,.]+?)#{AUDITOR_NAME_END}/i
    CONTACT_FORM_REGEX = /\b(?:aide|form|contact)/i
    LAW_DATE = Date.new(2005, 2, 11)
    SECTIONS = {
      audit_date: ["Établissement de cette déclaration d’accessibilité", :next],
      audit_update_date: ["Établissement de cette déclaration d’accessibilité", :next],
      compliance_rate: ["Résultats des tests", :next],
      standard: ["État de conformité", "Contenus non accessibles"],
      auditor: ["Résultats des tests", :next],
      mentions_article: [:previous, "État de conformité"],
      contact_email: ["Retour d'information et contact", :next],
      contact_form: ["Retour d'information et contact", :next]
    }.freeze

    store_accessor :data, :audit_date, :audit_update_date, :compliance_rate, :standard, :auditor, :mentions_article, :contact_email, :contact_form, :misplaced_fields

    def tooltip?
      !(completed? && found_required?)
    end

    def audit_date
      super&.to_date
    end

    def misplaced?(field)
      misplaced_fields&.include?(field.to_s)
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

    def find_info(field)
      value = extract(field, SECTIONS[field])
      return value if value.present?

      value = extract(field, nil)
      misplaced_fields << field.to_s if value.present?
      value
    end

    def custom_badge_status
      found_required? ? :success : :new
    end

    def custom_badge_text
      found_required? ? human_compliance_rate : t("checks.analyze_accessibility_page.missing_data")
    end

    private

    def extract(field, between_headings)
      text = accessibility_page.text(between_headings:)

      case field
      when :audit_date then extract_date(text.scan(AUDIT_DATE_PATTERN))
      when :audit_update_date then extract_date(text.scan(AUDIT_UPDATE_DATE_PATTERN))
      when :compliance_rate then compliance_rate_in(text)
      when :standard then standard_in(text)
      when :auditor then auditor_in(text)
      when :mentions_article then text.include?(LAW_NUMBER)
      when :contact_email then email_in(text, accessibility_page.mailto_addresses(between_headings:))
      when :contact_form then contact_form_in(accessibility_page.links(between_headings:))
      end
    end

    def standard_in(text)
      text.scan(STANDARD_PATTERN).flatten.compact.sort_by(&:length).last
    end

    def auditor_in(text)
      text.match(AUDITOR_PATTERN)&.[](1)&.strip
    end

    def email_in(text, mailtos)
      email_in_text = text.scan(Page::MAIL_PATTERN).first&.gsub("(at)", "@")

      email_in_text.presence || mailtos.first
    end

    def contact_form_in(links)
      link = links.find { |link| CONTACT_FORM_REGEX.match?(link.text) && CONTACT_FORM_REGEX.match?(link.href) }
      link ||= links.find { |link| CONTACT_FORM_REGEX.match?(link.text) || CONTACT_FORM_REGEX.match?(link.href) }
      link&.href
    end

    def compliance_rate_in(text)
      matches = text.scan(COMPLIANCE_PATTERN)

      return if matches.empty?

      most_recent_match = matches.last
      rate_string = most_recent_match.compact.first
      rate = rate_string.tr(",", ".").to_f

      rate % 1 == 0 ? rate.to_i : rate
    end

    def found_required?
      [:audit_date, :compliance_rate, :mentions_article].all? { send(it).present? }
    end

    def compute_found
      !data.nil?
    end

    def compute_conform
      found_required?
    end

    def analyze!
      return unless accessibility_page

      self.misplaced_fields = [] # FIXME: no [], just nil

      {
        audit_date: find_info(:audit_date),
        audit_update_date: find_info(:audit_update_date),
        compliance_rate: find_info(:compliance_rate),
        standard: find_info(:standard),
        auditor: find_info(:auditor),
        mentions_article: find_info(:mentions_article),
        contact_email: find_info(:contact_email),
        contact_form: find_info(:contact_form),
        misplaced_fields:
      }
    end

    def month_names
      @month_names ||= begin
        names = t("date.month_names")[1..] + t("date.abbr_month_names")[1..]
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
