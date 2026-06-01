FactoryBot.define do
  factory :site do
    sequence(:url) { |n| "https://www.example-#{n}.com/" }
    sequence(:normalized_url) { |n| "example-#{n}.com" }
    team { association :team }
    audits { [association(:audit)] }

    trait :completed do
      after(:create) do |site|
        site.audits.first.update!(completed_at: 1.day.ago)
        site.update!(last_audited_at: 1.day.ago)
      end
    end

    trait :with_data do
      completed
      after(:create) do |site|
        audit = site.last_audit
        Check.names.each do |check_name|
          check = audit.send(check_name)
          data = build(:check, check_name, :with_data).data
          check.update!(data:)

          transition = check.check_transitions.find_or_initialize_by(most_recent: true)
          transition.update!(to_state: :completed, sort_key: 0)
        end
      end
    end
  end
end
