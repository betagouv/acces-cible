FactoryBot.define do
  factory :audit_batch do
    user { association :user }
    kind { :manual }

    trait :csv_import do
      kind { :csv_import }
    end

    trait :launched do
      status { :launched }
    end
  end
end
