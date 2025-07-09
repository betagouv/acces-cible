# frozen_string_literal: true

def fake_auth_hash(email, siret, org)
  user = FactoryBot.build(:user, email:, siret:)

  OmniAuth::AuthHash.new(
    {
      provider: "proconnect-cucumber",
      uid: user.uid,
      info: {
        email: user.email,
      },
      extra: {
        raw_info: {
          given_name: user.given_name,
          usual_name: user.usual_name,
          email: user.email,
          siret: user.siret,
          organizational_unit: org
        }
      }
    }
  )
end

Quand("je suis {string} avec le SIRET {int} de l'organisation {string}") do |email, siret, org|
  OmniAuth.config.mock_auth[:proconnect] = fake_auth_hash(email, siret, org)
end

Quand("je me pro-connecte") do
  steps %(
    Quand je me rends sur la page d'accueil
    Et que je clique sur "Se connecter"
    Et que je clique sur "S'identifier avec ProConnect"
  )
end
