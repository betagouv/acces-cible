FactoryBot.define do
  factory :audit do
    user { association :user }
    audit_batch { nil }
    site { association :site, audits: [instance] }

    trait :draft do
      audit_batch { association :audit_batch, strategy: :create }
    end

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
