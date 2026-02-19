module ApplicationHelper
  include Pagy::Frontend
  include DsfrHelper
  include PageHelper
  include IconHelper


  def or_separator
    tag.p(class: "fr-hr-or fr-my-4w") { t("shared.or") }
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
    else
      dsfr_badge(status:) { text }
    end
  end

  def sortable_header(text, param, **options)
    current_sort = params.dig(:sort, param)&.downcase&.to_sym
    direction = current_sort == :asc ? :desc : :asc
    link_params = params.permit(:page, :limit, filter: {}).merge(sort: { param => direction })
    link_text = t("shared.sort_by", column: text, direction: t("shared.#{direction}"))
    options[:title] ||= link_text
    options["aria-label"] ||= link_text

    if current_sort.present?
      arrow = [:arrow, direction == :asc ? :down : :up]
    else
      arrow = [:arrow, :up, :down]
    end

    "#{text} #{link_icon(arrow, "", { params: link_params }, options.merge(btn: :sort, size: :sm, line: true))}".html_safe
  end

  def set_focus(selector)
    tag.div(hidden: true, data: { controller: :focus, "focus-selector-value": "##{selector}" })
  end

  def aria_sort(param)
    return unless (current_sort = params.dig(:sort, param)&.downcase&.to_sym)

    "aria-sort=#{current_sort == :asc ? :descending : :ascending}"
  end

  def root?
    request.path == "/"
  end

  def current_version
    ENV["CONTAINER_VERSION"] || "local"
  end

  def flatten_params(*keys)
    params.slice(*keys).permit!.to_h.flat_map do |key, value|
      flatten_params_hash(key.to_s, value)
    end.to_h
  end

  private

  def flatten_params_hash(prefix, value)
    if value.is_a?(Hash) || value.is_a?(ActionController::Parameters)
      value.flat_map do |k, v|
        flatten_params_hash("#{prefix}[#{k}]", v)
      end
    else
      [[prefix, value]]
    end
  end
end
