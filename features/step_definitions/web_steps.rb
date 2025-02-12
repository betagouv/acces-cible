# frozen_string_literal: true

Quand("je me rends sur la page d'accueil") do
  visit "/"
end

Alors("la page contient {string}") do |content|
  expect(page).to have_content(content)
end
