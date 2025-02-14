FactoryBot.define do
  factory :audit do
    site { association :site, url:, strategy: :build }
    url { "https://example.com" }

    trait :passed do
      status { "passed" }
    end

    trait :failed do
      status { "failed" }
    end

    trait :pending do
      status { "pending" }
    end

    trait :running do
      status { "running" }
    end
  end
end
