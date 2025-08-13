FactoryBot.define do
  factory :audit do
    url { "https://example.com" }
    site { association :site, url:, audits: [instance] }

    trait :without_checks do
      after(:create) do |audit, _eval|
        audit.checks.destroy_all
      end
    end

    trait :pending do
      status { "pending" }
    end

    trait :current do
      current { true }
    end

    trait :checked do
      checked_at { 1.day.ago }
      status { "passed" }
    end

    trait :passed do
      checked
      status { "passed" }
    end

    trait :failed do
      checked
      status { "failed" }
    end

    trait :mixed do
      checked
      status { "mixed" }
    end
  end
end
