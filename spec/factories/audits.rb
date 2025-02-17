FactoryBot.define do
  factory :audit do
    site { association :site, url:, strategy: :build }
    url { "https://example.com" }

    trait :pending do
      status { "pending" }
    end

    trait :passed do
      status { "passed" }
    end

    trait :failed do
      status { "failed" }
    end

    trait :mixed do
      status { "mixed" }
    end
  end
end
