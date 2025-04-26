FactoryBot.define do
  factory :accessibility_mention_check, class: "Checks::AccessibilityMention", aliases: [:check] do
    audit { association :audit }
  end
end
