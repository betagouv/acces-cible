module Checks
  class LanguageIndication < Check
    PRIORITY = 5

    store_accessor :data, :indication, :detected_code

    def custom_badge_text = indication || human(:empty)
    def custom_badge_status
      case indication
      when nil, "" then :error
      when /^(?:FR)(?:[_-][A-Z]{2})?$/i then :success
      else :warning
      end
    end

    private

    def analyze!
      {
        indication: find_language_indication,
        detected_code: detect_page_language,
      }
    end

    def find_language_indication
      root_page.dom.root.attributes["lang"]&.value&.strip
    end

    def language_code
      indication.to_s.strip.downcase.split(/_|-/).first
    end

    def detect_page_language
      CLD.detect_language(root_page.text)[:code].downcase
    end
  end
end
