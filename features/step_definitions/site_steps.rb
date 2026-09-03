# frozen_string_literal: true

def team
  @team ||= User.find_by(email: OmniAuth.config.mock_auth[:proconnect][:info][:email]).team
end

Quand("je rajoute un site {string} qui renvoie une réponse HTML normale") do |url|
  steps %(
   Sachant que le site "#{url}" renvoie une réponse HTML normale
   Et que je rajoute un site "#{url}"
  )
end

Sachantque("les sites suivants renvoient des réponses HTML normales pour leur page d'accueil et leur déclaration d'accessibilité :") do |table|
  table.raw.flatten.each do |url|
    steps %(
      Sachant que le site "#{url}" renvoie une réponse HTML normale pour la page d'accueil
      Et que le site "#{url}" renvoie une réponse HTML normale pour la déclaration d'accessibilité
    )
  end
end

# FIXME: because Chrome goes through the "real" network, we cannot use
# Webmock to mock the requests: Webmock will hijack `net/http` and
# other low-level Ruby network libraries but not the actual network,
# which means our test Chrome does go fetch actual websites. A good
# solution would be using toxiproxy[1] to feed as a proxy to
# Chrome and then mock responses + potential outages, etc.
#
# [1]: https://github.com/Shopify/toxiproxy

# In the meantime mock our Browser.get method instead but that is NOT
# NICE and we should do something about it soon.
Sachantque("le site {string} renvoie une réponse HTML normale pour la page d'accueil") do |url|
  fake_html = <<~HTML
    <html>
      <head>
        <title>Site title</title>
      </head>
      <body>
        <h1>Hello</h1>
      </body>
    </html>
  HTML

  allow(Browser)
    .to receive(:get)
          .with(url)
          .and_return(
            body: fake_html,
            status: 200,
            content_type: "text/html",
            current_url: url
          )
end

Sachantque("le site {string} renvoie {string} pour la page d'accueil") do |url, html|
  allow(Browser)
    .to receive(:get)
          .with(url)
          .and_return(
            body: html,
            status: 200,
            content_type: "text/html",
            current_url: url
          )
end

Sachantque("l'adresse {string} renvoie {string}") do |url, html|
  allow(Browser)
    .to receive(:get)
          .with(url)
          .and_return(
            body: html,
            status: 200,
            content_type: "text/html",
            current_url: url
          )
end

Sachantque("le site {string} renvoie {string} pour la déclaration d'accessibilité") do |url, str|
  step(%(le site "#{url}" renvoie "#{str}" à l'adresse "#{url}/accessibilité" pour la déclaration d'accessibilité))
end

Sachantque("le site {string} renvoie {string} à l'adresse {string} pour la déclaration d'accessibilité") do |_url, str, declaration_url|
  page = Page.new(url: declaration_url, root: declaration_url, html: str)

  allow(Crawler).to receive(:new).and_return(instance_double(Crawler, find_page: page))
end

Quand("le site {string} ne trouve pas de page d'accessibilité") do |string|
  allow(Crawler).to receive(:new).and_return(instance_double(Crawler, find_page: nil))
end

Sachantque("le site {string} renvoie une réponse HTML normale pour la déclaration d'accessibilité") do |url|
  fake_html = <<~HTML
    <html>
      <head>
        <title>Site title</title>
      </head>
      <body>
        <h1>Hello</h1>
      </body>
    </html>
  HTML

  step(%(le site "#{url}" renvoie "#{fake_html}" pour la déclaration d'accessibilité))
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

Quand("je rajoute un site {string}") do |url|
  steps %(
    Quand je clique sur "Lancer une évaluation"
    Et que je choisis "Saisir des adresses"
    Et que je clique sur "Continuer"
    Et que je remplis "Adresse du site" avec "#{url}"
    Et que je clique sur "Continuer"
    Et que je clique sur "Continuer"
    Et que je clique sur "Lancer l'évaluation"
    Et que je clique sur "Voir la fiche de #{Link.url_without_scheme_and_www(url)}"
  )
end

Quand("je possède un site {string} avec des données") do |url|
  site = FactoryBot.create(:site, :with_data, url:, team:)
  site.reload
end

Quand("le site {string} a les étiquettes {string}") do |url, tags_str|
  site = team.sites.find_by(url:)
  tag_names = tags_str.split(",").map(&:strip)
  tag_names.each do |name|
    tag = FactoryBot.create(:tag, name:, team:)
    site.tags << tag
  end
end

Alors("la page contient un lien vers {string}") do |url|
  url_without_scheme_and_www = Link.url_without_scheme_and_www(url)
  expect(page).to have_content(url_without_scheme_and_www)
end

Alors("la page contient un tableau") do
  expect(page).to have_css("table")
end

Alors("la page contient toutes les vérifications du site {string} avec le préfixe {string}") do |url, prefix|
  site = team.sites.find_by(url:)
  expect(page).to have_css("table") if prefix.present?
  site.last_audit.checks.each do |check|
    expect(page).to have_content(check.class.table_header)
  end
end

Alors("la page contient un tableau avec toutes les vérifications du site {string}") do |url|
  site = team.sites.find_by(url:)
  expect(page).to have_css("table")
  site.last_audit.checks.each do |check|
    expect(page).to have_content(check.table_header)
  end
end

Alors('la carte {string} indique {string}') do |title, str|
  expect(find("section.audit-card", text: title)).to have_content(str)
end

Alors('la carte {string} n\'indique pas {string}') do |title, str|
  expect(find("section.audit-card", text: title)).not_to have_content(str)
end

Alors('le résumé {string} indique {string}') do |label, str|
  expect(find(".summary-section", text: label)).to have_content(str)
end

Alors('la vérification {string} de la carte {string} indique {string}') do |check_name, card_title, str|
  card = find("section.audit-card", text: card_title)
  expect(card.find("th", text: check_name).ancestor("tr")).to have_content(str)
end

Alors('la vérification {string} de la carte {string} contient un lien vers {string}') do |check_name, card_title, href|
  card = find("section.audit-card", text: card_title)
  expect(card.find("th", text: check_name).ancestor("tr")).to have_link(href: href)
end

Quand("je choisis {string} dans le menu principal") do |item|
  within("nav[aria-label='Menu principal']") do
    click_link_or_button(item)
  end
end

Alors('la page retourne un CSV dont une ligne commence par {string}') do |str|
  expect(page.body.lines.one? { |line| line.start_with?(str) }).to be_truthy
end

Alors('la page retourne un CSV qui contient strictement les sites {string}') do |str|
  sites = str.delete(' ').split(",")
  expect(page.body.lines.count).to eq(sites.count + 1)

  sites.each do |site|
    expect(page.body.lines.one? { |line| line.start_with?(site) }).to be_truthy
  end
end
