FactoryBot.define do
  factory :site do
    sequence(:url) { |n| "https://www.example-#{n}.com/" }
    team { association :team }

    trait :checked do
      after(:create) do |site|
        audit = site.audits.current.first || create(:audit, :current, site:, url: site.url)
        audit.update!(checked_at: 1.day.ago)
      end
    end
  end
end
