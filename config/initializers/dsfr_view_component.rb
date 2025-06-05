module DsfrComponentsHelper
  alias_method :buggy_dsfr_accordion_section, :dsfr_accordion_section

  def dsfr_accordion_section(...)
    buggy_dsfr_accordion_section(...).squish.gsub('<button class="fr-accordion__btn"', '<button type="button" class="fr-accordion__btn"').html_safe
  end
end
