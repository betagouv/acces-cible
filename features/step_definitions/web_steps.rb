# frozen_string_literal: true

Quand("je recharge la page") do
  refresh
end

Alors("le champ {string} contient {string}") do |label, value|
  expect(page).to have_field(label, with: value)
end

Alors("la case {string} est cochée") do |label|
  expect(page).to have_checked_field(label)
end

Alors("la case {string} n'est pas cochée") do |label|
  expect(page).to have_unchecked_field(label)
end
