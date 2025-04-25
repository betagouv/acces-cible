FactoryBot.define do
  factory :site do
    sequence(:url) { |n| "https://www.example-#{n}.com/" }

    trait :checked do
      audit { association :audit, :checked, site: instance }
    end
  end
end
