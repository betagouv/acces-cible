module Checks
  class LanguageIndication < Check
    store_accessor :data, :indication

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
      { indication: find_language_indication }
    end

    def find_language_indication
      root.dom.root.attributes["lang"]&.value
    end
  end
end
