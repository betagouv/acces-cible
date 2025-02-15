module Checks
  class LanguageIndication < Check
    private

    def analyze!
      { indication: find_language_indication }
    end

    def find_language_indication
      root.dom.root.attributes["lang"]&.value
    end
  end
end
