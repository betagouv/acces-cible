FactoryBot.define do
  factory :user do
    provider { Faker::Company.name }
    uid { Faker::Internet.unique.uuid }
    email { Faker::Internet.email }
    given_name { Faker::Name.last_name }
    usual_name { Faker::Name.first_name }
    siret { Faker::Company.french_siret_number }
  end
end
