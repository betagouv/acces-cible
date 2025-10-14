# frozen_string_literal: true

Quand("je possède un fichier {string} qui contient") do |path, content|
  File.write(path, content)
end

Quand("je filtre par étiquette {string}") do |tag|
  steps %(
    Quand je sélectionne "#{tag}" pour "Filtrer par étiquette"
    Et que je clique sur "Filtrer"
  )
end

Quand("je recherche {string}") do |term|
  fill_in "Rechercher", with: term
  click_button "Rechercher"
end
