module Checks
  class AccessibilityMention < Check
    MENTION_REGEX = /accessibilit[ée]\s*:?\s*(?<level>non|partiellement|totalement)\s+conforme/iu

    store_accessor :data, :mention

    def mention? = mention.present?

    def custom_badge_text = human("mentions.", count: nil)[mention.to_s.to_sym]
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
      (root_page.text.match(MENTION_REGEX)&.named_captures || {})["level"]&.downcase
    end
  end
end
