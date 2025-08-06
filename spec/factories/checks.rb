FactoryBot.define do
  factory :accessibility_mention_check, class: "Checks::AccessibilityMention", aliases: [:check] do
    audit { association :audit }

    trait :ready do
      after(:create) do |check, _eval|
        CheckTransition.create!(to_state: "ready", check: check, most_recent: true, sort_key: 10)
      end
    end
  end
end
