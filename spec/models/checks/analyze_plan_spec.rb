require "rails_helper"

RSpec.describe Checks::AnalyzePlan do
  let(:link_href) { "#{root}/plan_annuel.pdf" }
  let(:href_years) { [current_year] }
  let(:href_text) { "Plan annuel d'accessibilite" }
  let(:href_with_years) { "#{root}/plan-annuel-#{current_year}.pdf" }
  let(:text_years) { [current_year + 1] }
  let(:text_with_years) { "Plan annuel d'accessibilite #{current_year + 1}" }

  current_year = Date.current.year
  year_range_validity_cases = {
    [current_year + 2] => false,
    [current_year + 1] => true,
    [current_year] => true,
    [current_year - 1] => true,
    [current_year - 2] => false
  }

  non_matching_text_cases = [
    "plan accessibilite #{current_year}",
    "plan d'accesibilite #{current_year + 1}",
    "plan annuel mise accessibilite #{current_year}",
  ]

  matching_text_cases = {
    "plan annuel d'accessibilite numerique #{current_year}" => { years: [current_year], valid_years: true },
    "plan annuel d'accessibilite numerique #{current_year - 5}" => { years: [current_year - 5], valid_years: false },
    "plan annuel de mise en accessibilite #{current_year - 1}-#{current_year}" => { years: [current_year - 1, current_year], valid_years: true },
    "plan annuel de mise en accessibilite #{current_year}-#{current_year + 10}" => { years: [current_year, current_year + 10], valid_years: false },
    "plan annuel #{current_year}" => { years: [current_year], valid_years: true },
    "plan d'action #{current_year + 1}" => { years: [current_year + 1], valid_years: true },
    "plan d'actions #{current_year}-#{current_year + 1}" => { years: [current_year, current_year + 1], valid_years: true },
    "plan #{current_year} d'action" => { years: [current_year], valid_years: true },
    "PLAN ANNUEL D'ACCESSIBILITE #{current_year + 1}" => { years: [current_year + 1], valid_years: true },
  }

  it_behaves_like "an accessibility document analyzer", matching_text_cases, non_matching_text_cases, year_range_validity_cases
end
