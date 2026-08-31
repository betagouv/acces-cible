module ApplicationHelper
  include DsfrHelper
  include PageHelper
  include IconHelper
  include JdmaHelper

  EXTERNAL_LINK_CLASSES = "fr-link fr-link--sm fr-link--icon-right fr-icon-external-link-line".freeze
  TRUNCATION_LENGTH = 35.freeze

  def or_separator
    tag.p(class: "fr-hr-or fr-my-4w") { t("shared.or") }
  end

  def external_link_to(url, text)
    content = safe_join([text, tag.span(t("shared.new_window"), class: "fr-sr-only")])
    link_to(content, url, class: EXTERNAL_LINK_CLASSES, target: "_blank", rel: "noopener noreferrer")
  end

  def email_link_to(email)
    mail_to(email, class: "fr-link fr-link--sm fr-link--icon-right fr-icon-mail-line")
  end

  def card_with_header(title:, description: nil, &block)
    tag.section(class: "rounded audit-card fr-mb-3w") do
      header = capture do
        concat tag.h3(title, class: "fr-h4 fr-mb-0")
        concat tag.p(description, class: "fr-text--sm fr-mb-0 fr-mt-1v") if description
      end

      concat tag.div(header, class: "header")
      concat tag.div(capture(&block), class: "body")
    end
  end

  def muted_dash
    tag.span(t("shared.dash"), class: "fr-text-mention--grey")
  end

  def badge(status:, text: nil, link: nil, hover: false, no_icon: false)
    return hover_badge(status, text, link, no_icon) if hover

    dsfr_badge(status:, no_icon:) { link ? link_to(text, link) : text }
  end

  def sortable_header(text, param, **options)
    current_sort = params.dig(:sort, param)&.downcase&.to_sym
    direction = current_sort == :asc ? :desc : :asc
    link_params = params.permit(:page, :limit, filter: {}, sort: {}).merge(sort: { param => direction })
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

  def hover_badge(status, text, link, no_icon)
    label = tag.span(class: "fr-sr-only") { text }
    return dsfr_badge(status:, no_icon:, html_attributes: { role: :tooltip, tabindex: 0, title: text }) { label } unless link

    link_to link, class: class_names("fr-badge", "fr-badge--#{status}", ("fr-badge--no-icon" if no_icon)), role: :tooltip, title: text + t("shared.new_window"), target: :_blank, rel: :noopener do
      label
    end
  end

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
