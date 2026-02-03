require "rails_helper"

RSpec.describe Checks::AnalyzeSchema do
  let(:default_body) { "<p>Texte sans lien ni schema</p>" }
  let(:link_href) { "#{root}/schema_pluriannuel.pdf" }
  let(:href_years) { [current_year - 1, current_year + 1] }
  let(:href_text) { "Schema pluriannuel d'accessibilite" }
  let(:href_with_years) { "#{root}/schema-#{href_years.join("-")}.pdf" }
  let(:text_years) { href_years }
  let(:text_with_years) { "Schema pluriannuel d'accessibilite #{href_years.join("-")}" }

  current_year = Date.current.year
  max_year_distance = described_class::MAX_YEARS_VALIDITY
  min_year = current_year - max_year_distance
  max_year = current_year + max_year_distance
  last_year = current_year - 1
  next_year = current_year + 1

  year_range_validity_cases = {
    [current_year] => true,
    [last_year] => false,
    [next_year] => false,
    [min_year, current_year] => true,
    [current_year, max_year] => true,
    [last_year, next_year] => true,
    [min_year - 1, last_year] => false,
    [next_year, max_year + 1] => false,
  }

  non_matching_text_cases = [
    "schema pluriannuel d'accessibillite numerique #{current_year}",
    "schema annuel accessibilite #{current_year}",
    "accessibilite - schema #{current_year}",
  ]

  matching_text_cases = {
    "schema pluriannuel #{current_year - 1}-#{current_year + 10}" => { years: [current_year - 1, current_year + 10], valid_years: false },
    "schema annuel d'accessibilite #{current_year - 5}" => { years: [current_year - 5], valid_years: false },
    "schema pluriannuel #{current_year - 1}-#{current_year + 1}" => { years: [current_year - 1, current_year + 1], valid_years: true },
    "schema pluriannuel d'accessibilite numerique #{current_year}" => { years: [current_year], valid_years: true },
    "schema pluriannuel de mise en accessibilite #{current_year - 1}-#{current_year + 1}" => { years: [current_year - 1, current_year + 1], valid_years: true },
    "schema pluriannuel RGAA #{current_year - 1}-#{current_year + 1}" => { years: [current_year - 1, current_year + 1], valid_years: true },
    "schema d'accessibilite pluriannuel #{current_year - 1}-#{current_year + 1}" => { years: [current_year - 1, current_year + 1], valid_years: true },
    "schema annuel d'accessibilite #{current_year}" => { years: [current_year], valid_years: true },
    "SCHEMA PLURIANNUEL D'ACCESSIBILITE #{current_year}" => { years: [current_year], valid_years: true },
  }

  it_behaves_like "an accessibility document analyzer", matching_text_cases, non_matching_text_cases, year_range_validity_cases
end
