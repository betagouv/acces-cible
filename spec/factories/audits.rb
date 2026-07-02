FactoryBot.define do
  factory :audit do
    user { association :user }
    site { association :site, audits: [instance] }

    trait :without_checks do
      after(:create) do |audit, _eval|
        audit.checks.destroy_all
      end
    end

    trait :completed do
      completed_at { 1.day.ago }
    end
  end
end
