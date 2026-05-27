module JdmaHelper
  JDMA_ASSET_HOST = "https://jedonnemonavis.numerique.gouv.fr".freeze
  JDMA_BUTTON_IMAGE = "#{JDMA_ASSET_HOST}/static/buttons/button-problem-ghost-light.svg".freeze
  JDMA_WIDGET_SCRIPT_URL = "#{JDMA_ASSET_HOST}/static/jdma-modal-widget.js".freeze

  def jdma_widget_config
    return if ENV["JDMA_FORM_URL"].blank?

    {
      form_url: ENV["JDMA_FORM_URL"],
      button_image: JDMA_BUTTON_IMAGE,
      button_label: t("jdma.button_label"),
    }
  end

  def show_jdma_widget?
    authenticated? && ENV["JDMA_FORM_URL"].present?
  end
end
