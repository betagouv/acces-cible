FactoryBot.define do
  factory :site do
    sequence(:slug) { |n| "www.example-#{n}.com" }
  end
end
