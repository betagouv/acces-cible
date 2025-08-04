module ApplicationHelper
  include Pagy::Frontend
  include DsfrHelper
  include PageHelper
  include IconHelper

  # Remove all leading whitespace to prevent markdown code block interpretation (strip_heredoc preserves relative indentation)
  def safe_unindent(string)
    string.gsub(/^\s+/, "").html_safe
  end

  def time_ago(datetime)
    datetime = datetime.in_time_zone if datetime.respond_to?(:in_time_zone)
    time = distance_of_time_in_words_to_now(datetime)
    t("shared.#{ datetime.before?(Time.zone.now) ? :time_ago : :time_until }", time:)
  end

  def or_separator = tag.p(class: "fr-hr-or fr-my-4w") { t("shared.or") }

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
    link_params = params.permit(:page, search: {}).merge(sort: { param => direction })
    options[:title] ||= t("shared.sort_by", column: text, direction: t("shared.#{direction}"))
    if current_sort.present?
      arrow = [:arrow, direction == :asc ? :down : :up]
    else
      arrow = [:arrow, :up, :down]
    end
    "#{text} #{link_icon(arrow, text, { params: link_params }, options.merge(btn: :sort, size: :sm, sr_only: true, line: true))}".html_safe
  end

  def set_focus(selector)
    tag.div(hidden: true, data: { controller: :focus, "focus-selector-value": "##{selector}" })
  end

  def aria_sort(param)
    return unless (current_sort = params.dig(:sort, param)&.downcase&.to_sym)

    "aria-sort=#{current_sort == :asc ? :descending : :ascending}"
  end

  def root? = request.path == "/"

  def current_git_commit
    ENV["CONTAINER_VERSION"] || `git show -s --format=%H`
  end
end
