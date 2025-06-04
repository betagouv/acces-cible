FactoryBot.define do
  factory :tag do
    name { Faker::Lorem.unique.words(number: rand(1..4)).join(" ") }
    team
  end
end
