FactoryBot.define do
  factory :team do
    siret { Faker::Company.french_siret_number }
  end
end
