module Checks
  class AccessibilityMention < Check
    PRIORITY = 10
    MENTION_REGEX = /accessibilit[ée]     # Match "accessibilité" or "accessibilite"
                    \s*                   # Optional whitespace
                    (?:\w+\s+){0,3}       # Optional words (up to 3)
                    :?                    # Optional colon
                    \s*                   # Optional whitespace
                    (?:\w+\s+){0,3}       # Optional words (up to 3)
                    (?<level>non|partiellement|totalement)  # Capture the level
                    \s+                   # Required whitespace
                    conforme              # Match "conforme"
                    /iux                  # Case insensitive, Unicode, allow comments and whitespace

    store_accessor :data, :mention
    delegate :text, to: :root_page, prefix: true

    def mention_text = human("mentions.#{mention || 'none'}")

    private

    def custom_badge_text = mention_text
    def custom_badge_status
      { nil => :error,
        non: :warning,
        partiellement: :new,
        totalement: :success }[mention&.to_sym]
    end

    def analyze!
      { mention: find_mention }
    end

    def find_mention
      (root_page_text.match(MENTION_REGEX)&.named_captures || {})["level"]&.downcase
    end
  end
end
