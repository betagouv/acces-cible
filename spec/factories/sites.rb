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

    trait :with_data do
      checked
      after(:create) do |site|
        audit = site.audit
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
