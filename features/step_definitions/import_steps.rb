# frozen_string_literal: true

Quand("je possède un fichier {string} qui contient") do |path, content|
  File.write(path, content)
end

Quand("j'importe le fichier CSV {string}") do |path|
  steps %(
    Sachant que je choisis "Mes évaluations" dans le menu principal
    Et que je clique sur "Lancer une évaluation"
    Et que je choisis "Importer un CSV"
    Et que je clique sur "Continuer"
    Et que j'attache le fichier "#{path}" pour le champ "Fichier CSV"
    Et que je clique sur "Continuer"
    Et que je clique sur "Continuer"
    Et que je clique sur "Lancer l'évaluation"
    Et que le lancement est terminé
  )
end

Quand("je rajoute un CSV de {int} sites") do |n|
  csv = FactoryBot
          .build_list(:site, n)
          .map(&:url)
          .unshift("URL")
          .join("\n")

  steps %(
    Sachant que je possède un fichier "tmp/sites.csv" qui contient
      """
      #{csv}
      """
    Et que j'importe le fichier CSV "tmp/sites.csv"
  )
end
