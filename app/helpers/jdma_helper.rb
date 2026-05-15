module JdmaHelper
  JDMA_HOST = "https://jedonnemonavis.numerique.gouv.fr".freeze

  def jdma_widget_config
    return staging_jdma_widget_config if Rails.application.staging?
    return production_jdma_widget_config if Rails.env.production?

    nil
  end

  private

  def staging_jdma_widget_config
    {
      form_url: "#{JDMA_HOST}/Demarches/avis/2229?button=4664",
      button_image: "#{JDMA_HOST}/static/buttons/button-remark-solid-light.svg",
      button_label: t("jdma.staging_button_label"),
    }
  end

  def production_jdma_widget_config
    {
      form_url: "#{JDMA_HOST}/Demarches/avis/2230?button=4666",
      button_image: "#{JDMA_HOST}/static/buttons/button-problem-solid-light.svg",
      button_label: t("jdma.production_button_label"),
    }
  end
end
