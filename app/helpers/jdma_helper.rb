module JdmaHelper
  JDMA_ASSET_HOST = "https://jedonnemonavis.numerique.gouv.fr".freeze
  JDMA_BUTTON_IMAGE = "#{JDMA_ASSET_HOST}/static/buttons/button-problem-ghost-light.svg".freeze
  JDMA_WIDGET_SCRIPT_URL = "#{JDMA_ASSET_HOST}/static/jdma-modal-widget.js".freeze

  def jdma_form_url
    ENV["JDMA_FORM_URL"]
  end

  def jdma_widget_config
    return if jdma_form_url.blank?

    {
      form_url: jdma_form_url,
      button_image: JDMA_BUTTON_IMAGE,
      button_label: t("jdma.button_label"),
    }
  end

  def show_jdma_widget?
    authenticated? && jdma_form_url.present?
  end
end
