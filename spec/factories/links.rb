FactoryBot.define do
  factory :link do
    sequence(:href) { |n| "https://www.example.com/page#{n}" }
    sequence(:text) { |n| "Page #{n}" }
    initialize_with { new(**attributes.merge(href:, text:)) }
  end
end
