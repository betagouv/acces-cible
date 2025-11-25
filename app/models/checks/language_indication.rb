module Checks
  class LanguageIndication < Check
    PRIORITY = 5

    store_accessor :data, :indication, :detected_code

    def custom_badge_text
      indication || human(:empty)
    end

    def custom_badge_status
      if indication.blank?
        :error
      elsif language_code == (detected_code || "fr") # Fallback for checks before page language detection
        :success
      else
        :warning
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
      # Renvoie le code de langue, ou "un" (pour "unknown")
      CLD.detect_language(root_page.text)[:code].downcase
    end
  end
end
