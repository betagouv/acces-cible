module ApplicationHelper
  include Pagy::Frontend

  # Automagically fetch title from @title, content_for(:title), resource.to_title, or controller/action/title I18n lookup
  def page_title
    return @title unless @title.blank?
    return content_for(:title) if content_for?(:title)
    return resource.to_title if action_name == "show"

    action = case action_name.to_sym
    when :create then :new
    when :update then :edit
    else action_name
    end
    t("#{controller_name}.#{action}.title")
  end

  def head_title
    if root?
      [t("global.service_name"), t("global.service_description")].compact_blank.join(" : ")
    else
      [page_title, t("global.service_name")].compact_blank.join(" - ")
    end
  end

  def dsfr_table(caption:, size: :md, scroll: true, border: false, **html_attributes, &block)
    render(Dsfr::TableComponent.new(caption:, size:, scroll:, border:, html_attributes:), &block)
  end

  def root? = request.path == "/"

  def time_ago(datetime)
    t("shared.time_ago", time: distance_of_time_in_words_to_now(datetime))
  end

  def paginate
    render "shared/paginate", pagy: @pagy if @pagy && @pagy.pages > 1
  end

  def badge(status, text = nil, tooltip: false, &block)
    status, text = *status if status.is_a?(Array)
    text ||= yield(block)
    html_attributes = tooltip ? { role: :tooltip, tabindex: 0, title: text } : {}
    dsfr_badge(status:, html_attributes:) { tooltip ? tag.span(class: "fr-sr-only") { text } : text }
  end
end
