# frozen_string_literal: true

Quand("je possède un fichier {string} qui contient") do |path, content|
  File.write(path, content)
end
