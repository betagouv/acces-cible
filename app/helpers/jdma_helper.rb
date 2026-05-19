module JdmaHelper
  JDMA_HOST = "https://jedonnemonavis.numerique.gouv.fr".freeze
  JDMA_STAGING_FORM_URL = "#{JDMA_HOST}/Demarches/avis/2229?button=4675".freeze
  JDMA_PRODUCTION_FORM_URL = "#{JDMA_HOST}/Demarches/avis/2230?button=4675".freeze
  JDMA_BUTTON_IMAGE = "#{JDMA_HOST}/static/buttons/button-problem-ghost-light.svg".freeze

  def jdma_widget_config
    return unless jdma_form_url

    {
      form_url: jdma_form_url,
      button_image: JDMA_BUTTON_IMAGE,
      button_label: t("jdma.button_label"),
    }
  end

  private

  def jdma_form_url
    return JDMA_STAGING_FORM_URL if Rails.application.staging?
    return JDMA_PRODUCTION_FORM_URL if Rails.env.production?

    nil
  end
end
