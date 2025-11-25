# frozen_string_literal: true

Quand("je possède un fichier {string} qui contient") do |path, content|
  File.write(path, content)
end

Quand("je rajoute un CSV de {int} sites") do |n|
  csv = FactoryBot
          .build_list(:site, n)
          .map(&:url)
          .unshift("URL")
          .join("\n")

  steps %(
    Sachant que je clique sur "Ajouter un site"
    Et que je possède un fichier "tmp/sites.csv" qui contient
      """
      #{csv}
      """
    Et que j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Et que je clique sur "Importer"
  )
end
