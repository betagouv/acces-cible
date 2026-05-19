module JdmaHelper
  JDMA_HOST = "https://jedonnemonavis.numerique.gouv.fr".freeze
  JDMA_STAGING_FORM_ID = "2229".freeze
  JDMA_PRODUCTION_FORM_ID = "2230".freeze
  JDMA_BUTTON_ID = "4675".freeze
  JDMA_BUTTON_IMAGE = "#{JDMA_HOST}/static/buttons/button-problem-ghost-light.svg".freeze

  def jdma_widget_config
    form_id = if Rails.application.staging?
      JDMA_STAGING_FORM_ID
    elsif Rails.env.production?
      JDMA_PRODUCTION_FORM_ID
    end

    return if form_id.nil?

    {
      form_url: "#{JDMA_HOST}/Demarches/avis/#{form_id}?button=#{JDMA_BUTTON_ID}",
      button_image: JDMA_BUTTON_IMAGE,
      button_label: t("jdma.button_label"),
    }
  end
end
