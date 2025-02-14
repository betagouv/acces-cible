FactoryBot.define do
  factory :check do
    audit { association :audit, checks: [instance] }
  end
end
