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
    render Dsfr::TableComponent.new(caption:, size:, scroll:, border:, html_attributes:), &block
  end

  def dsfr_sidemenu(title:, button: nil, sticky: false, full_height: false, right: false, &block)
    component = Dsfr::SidemenuComponent.new(title:, button:, sticky:, full_height:, right:)
    yield(component) if block_given?
    render component
  end

  def sort_link(text, param, **options)
    permitted_params = params.permit(:page)
    current_sort = params.dig(:sort, param)&.downcase&.to_sym
    direction = current_sort == :asc ? :desc : :asc
    link_params = permitted_params.merge(sort: { param => direction })
    options[:class] = class_names(
      options.delete(:class),
      "fr-link fr-link--icon-right fr-icon-arrow-#{direction == :asc ? :down : :up}-s-fill" => current_sort.present?
    ).presence
    options[:title] ||= t("shared.sort_by", column: text, direction: t("shared.#{direction}"))
    link_to text, url_for(params: link_params), **options
  end

  def root? = request.path == "/"

  def time_ago(datetime)
    time = distance_of_time_in_words_to_now(datetime)
    t("shared.#{ datetime.before?(Time.zone.now) ? :time_ago : :time_until }", time:)
  end

  def paginate
    render "shared/paginate", pagy: @pagy if @pagy && @pagy.pages > 1
  end

  def badge(status, text = nil, link: nil, tooltip: false, &block)
    status, text, link = *status if status.is_a?(Array)
    text ||= yield(block)
    case
    when tooltip && link
      link_to link, class: class_names("fr-badge", "fr-badge--#{status}"), role: :tooltip, title: text + t("shared.new_window"), target: :_blank, rel: :noopenner do
        tag.span(class: "fr-sr-only") { text }
      end
    when tooltip
      dsfr_badge(status:, html_attributes: { role: :tooltip, tabindex: 0, title: text }) { tag.span(class: "fr-sr-only") { text } }
    when link then dsfr_badge(status:) { link_to text, link }
    else dsfr_badge(status:) { text }
    end
  end
end
