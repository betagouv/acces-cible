module Checks
  class LanguageIndication < Check
    store_accessor :data, :indication

    private

    def custom_badge_text = indication || human(:empty)
    def custom_badge_status
      case indication
      when nil, "" then :error
      when /^(?:FR)(?:[_-][A-Z]{2})?$/i then :success
      else :warning
      end
    end

    def analyze!
      { indication: find_language_indication }
    end

    def find_language_indication
      root_page.dom.root.attributes["lang"]&.value
    end
  end
end
