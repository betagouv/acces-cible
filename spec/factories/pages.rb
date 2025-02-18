FactoryBot.define do
  factory :page do
    sequence(:url) { |n| "https://www.example-#{n}.com/" }
    initialize_with { new(**attributes.merge(url:)) }
  end
end
