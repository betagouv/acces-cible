FactoryBot.define do
  factory :audit do
    url { "https://example.com" }
    site { association :site, url:, audits: [instance] }

    trait :without_checks do
      after(:create) do |audit, _eval|
        audit.checks.destroy_all
      end
    end

    trait :current do
      current { true }
    end

    trait :checked do
      checked_at { 1.day.ago }
    end
  end
end
