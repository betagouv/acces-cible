# frozen_string_literal: true

Quand("je recharge la page") do
  refresh
end

Alors("le champ {string} contient {string}") do |label, value|
  expect(page).to have_field(label, with: value)
end
