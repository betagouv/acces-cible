FactoryBot.define do
  factory :site do
    sequence(:url) { |n| "https://www.example-#{n}.com/" }

    trait :checked do
      audits { [association(:audit, :checked, url:, site: instance, current: true)] }
    end
  end
end
