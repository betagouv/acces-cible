# frozen_string_literal: true

def team
  @team ||= User.find_by(email: OmniAuth.config.mock_auth[:proconnect][:info][:email]).team
end

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

Quand("je possède un site {string}") do |url|
  site = FactoryBot.create(:site, :checked, url:, team:)
  site.reload
  site.set_current_audit!
end

Quand("je possède un site {string} avec des données") do |url|
  site = FactoryBot.create(:site, :with_data, url:, team:)
  site.reload
  site.set_current_audit!
end

Quand("le site {string} a les étiquettes {string}") do |url, tags_str|
  site = team.sites.find_by_url(url:)
  tag_names = tags_str.split(",").map(&:strip)
  tag_names.each do |name|
    tag = FactoryBot.create(:tag, name:, team:)
    site.tags << tag
  end
end

Quand("je demande une nouvelle vérification du site {string}") do |url|
  site = team.sites.find_by_url(url:)
  site.audits.create!(url: site.url, current: false)
end

Alors("la page contient un lien vers {string}") do |url|
  url_without_scheme_and_www = Link.url_without_scheme_and_www(url)
  expect(page).to have_content(url_without_scheme_and_www)
end

Alors("la page contient un lien vers l'étiquette {string}") do |name|
  tag = team.tags.find_by(name:)
  expect(page).to have_link(href: tag_path(tag))
end

Alors("la page contient un tableau") do
  expect(page).to have_css("table")
end

Alors("la page contient toutes les vérifications du site {string} avec le préfixe {string}") do |url, prefix|
  site = team.sites.find_by_url(url:)
  expect(page).to have_css("table") if prefix.present?
  site.audit.all_checks.each do |check|
    expect(page).to have_content(check.class.table_header)
  end
end

Alors("la page contient un tableau avec toutes les vérifications du site {string}") do |url|
  site = team.sites.find_by_url(url:)
  expect(page).to have_css("table")
  site.audit.all_checks.each do |check|
    expect(page).to have_content(check.table_header)
  end
end

Alors("la page contient toutes les vérifications du site {string}") do |url|
  site = team.sites.find_by_url(url:)
  site.audit.all_checks.each do |check|
    expect(page).to have_content(check.human_type)
  end
end
