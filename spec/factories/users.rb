FactoryBot.define do
  factory :user do
    provider { Faker::Company.name }
    uid { Faker::Internet.unique.uuid }
    email { Faker::Internet.email }
    name { Faker::Name.name }
    siret { Faker::Company.french_siret_number }
  end
end
