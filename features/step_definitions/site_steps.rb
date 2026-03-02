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

Sachantque("le site {string} renvoie {string} pour la déclaration d'accessibilité") do |url, str|
  allow(FindAccessibilityPageService)
    .to receive(:find_page)
    .and_return(Page.new(url: "#{url}/accessibilité", root: "#{url}/accessibilité", html: str))
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
    Quand je clique sur "Ajouter un site"
    Et que je remplis "Adresse du site" avec "#{url}"
    Et que je clique sur "Ajouter"
  )
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
  site.audit.checks.each do |check|
    expect(page).to have_content(check.class.table_header)
  end
end

Alors("la page contient un tableau avec toutes les vérifications du site {string}") do |url|
  site = team.sites.find_by_url(url:)
  expect(page).to have_css("table")
  site.audit.checks.each do |check|
    expect(page).to have_content(check.table_header)
  end
end

Alors("la page contient toutes les vérifications du site {string}") do |url|
  site = team.sites.find_by_url(url:)
  site.audit.checks.each do |check|
    expect(page).to have_content(check.human_type)
  end
end

Alors('la section {string} indique {string}') do |name, str|
  within(find('h2', text: name).ancestor('div', id: /checks_/)) do |section|
    expect(section).to have_content(str)
  end
end

Alors('la vérification {string} indique {string}') do |name, state|
  within(find('h2', text: name).sibling('.fr-badge')) do |badge|
    expect(badge).to have_content state
  end
end

Quand("je choisis {string} dans le menu principal") do |item|
  within("nav[aria-label='Menu principal']") do
    click_link_or_button(item)
  end
end

Alors('la page contient un CSV dont une ligne commence par {string}') do |str|
  expect(page.body.lines.one? { |line| line.start_with?(str) }).to be_truthy
end
