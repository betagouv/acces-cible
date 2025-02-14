module Checks
  class AccessibilityMention < Check
    MENTION_REGEX = /accessibilit[ée]\s*:?\s*(?<level>non|partiellement|totalement)\s+conforme/iu

    def mention? = data[:mention].present?
    def human_mention = human("mentions.", count: nil)[mention.to_s.to_sym]

    private

    def analyze!
      { mention: find_mention }
    end

    def mention
      data[:mention]&.to_sym
    end

    def find_mention
      (root_page.text.match(MENTION_REGEX)&.named_captures || {})["level"]&.downcase
    end
  end
end
