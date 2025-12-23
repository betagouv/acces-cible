module Checks
  class AccessibilityMention < Check
    PRIORITY = 10
    MENTION_REGEX = /accessibilit[ée]     # Match "accessibilité" or "accessibilite"
                    (?:\s+\w+\s+site)?    # Optional words followed by " site" (like "du site")
                    \s*                   # Optional whitespace
                    :?                    # Optional colon
                    \s*                   # Optional whitespace
                    \(?                   # Optional open parenthesis
                    \s*                   # Optional whitespace
                    (?<level>non|partiellement|totalement)  # Capture the level
                    \s+                   # Required whitespace
                    conforme              # Match "conforme"
                    /iux # Case insensitive, Unicode, allow comments and whitespace

    store_accessor :data, :mention
    delegate :text, to: :root_page, prefix: true

    def mention_text
      completed? ? t("#{mention || 'none'}", scope: "checks.accessibility_mention.mentions") : ""
    end

    def custom_badge_text
      mention_text
    end

    def custom_badge_status
      { nil => :error,
        non: :warning,
        partiellement: :new,
        totalement: :success }[mention&.to_sym]
    end

    private

    def analyze!
      { mention: find_mention }
    end

    def find_mention
      (root_page_text.match(MENTION_REGEX)&.named_captures || {})["level"]&.downcase
    end
  end
end
