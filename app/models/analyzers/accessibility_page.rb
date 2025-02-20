module Analyzers
  class AccessibilityPage
    DECLARATION = /Déclaration d('|')accessibilité( RGAA)?/i
    ARTICLE = /(?:art(?:icle)?\.? 47|article 47) (?:de la )?loi (?:n[°˚]|num(?:éro)?\.?) ?2005-102 du 11 (?:février|fevrier) 2005/i
    DATE_PATTERN = /(?:réalisé(?:e)?(?:\s+le)?|du|en)\s+(?:(\d{1,2})(?:\s+|er\s+)?)?([a-zéû]+)\s+(\d{4})/i
    COMPLIANCE_PATTERN = /(?:taux de conformité(?:.+?)(?:est )?de|conforme à|révèle que(?:.+?)?(?:est )?à?) (\d+(?:,\d+)?(?:\.\d+)?)(?:\s*%| pour cent)/i
    STANDARD_PATTERN = /(?:au |des critères )?(?:(RGAA(?:[. ](?:version|v)?[. ]?\d+(?:\.\d+(?:\.\d+)?)?)?|(WCAG)))/i
    AUDITOR_PATTERN = /(?:par(?:\s+la)?(?:\s+société)?|par)\s+([^,]+?)(?:,| révèle| sur)/i

    attr_reader :page
    delegate :url, :title, :text, to: :page

    class << self
      def analyze(crawler)
        new(crawler).data
      end
    end

    def initialize(crawler: nil, page: nil)
      @crawler = crawler
      @page = page || (find_page if crawler) # Allow passing a page to simplify testing
    end
    private_class_method :new

    def data = page ? { url:, title:, audit_date:, compliance_rate:, standard:, auditor: } : {}

    def audit_date
      return unless (match = text.match(DATE_PATTERN))

      day = (match[1] || "1").to_i
      month = month_names[match[2].downcase]
      year = match[3].to_i

      Date.new(year, month, day)
    rescue Date::Error
      nil
    end

    def compliance_rate
      return unless (match = text.match(COMPLIANCE_PATTERN))

      rate = match[1].tr(",", ".").to_f
      rate % 1 == 0 ? rate.to_i : rate
    end

    def standard
      text.scan(STANDARD_PATTERN).flatten.compact.sort_by(&:length).last
    end

    def auditor
      text.match(AUDITOR_PATTERN)&.[](1)&.strip
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

    def likelihood_of(link)
      return 0 unless link.is_a?(Link)

      [
        link.text.match?(DECLARATION),
        link.href.match?("(declaration-)?accessibilite"),
        link.text.match?(Checks::AccessibilityMention::MENTION_REGEX)
      ].count(&:itself).then { |n| n.zero? ? -1 : n - 1 }
    end

    private

    attr_reader :crawler

    def find_page
      crawler.find do |current_page, queue|
        return current_page if accessibility_page?(current_page)

        sort_queue_by_likelihood(queue)
      end
    end

    def accessibility_page?(current_page)
      current_page.title.match?(DECLARATION) ||
        current_page.headings.any?(DECLARATION) ||
        current_page.text.match?(ARTICLE)
    end

    def sort_queue_by_likelihood(queue)
      queue.sort_by! { |link| likelihood_of(link) }
    end
  end
end
