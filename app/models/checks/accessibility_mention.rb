module Checks
  class AccessibilityMention < Check
    PRIORITY = 10
    MENTION_REGEX = /accessibilit[ée]\s*:?\s*(?<level>non|partiellement|totalement)\s+conforme/iu

    store_accessor :data, :mention

    def mention_text = human("mentions.", count: nil)[mention.to_s.to_sym]

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
      (root_page.text.match(MENTION_REGEX)&.named_captures || {})["level"]&.downcase
    end
  end
end
