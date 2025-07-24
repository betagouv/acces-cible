module ApplicationHelper
  include Pagy::Frontend

  TRUNCATE_LENGTH = 50

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
      [page_title.truncate(TRUNCATE_LENGTH), t("global.service_name")].compact_blank.join(" - ")
    end
  end

  # Remove all leading whitespace to prevent markdown code block interpretation (strip_heredoc preserves relative indentation)
  def safe_unindent(string)
    string.gsub(/^\s+/, "").html_safe
  end

  def dsfr_table(caption:, pagy: @pagy, size: :md, scroll: true, border: false, **html_attributes, &block)
    render Dsfr::TableComponent.new(caption:, pagy:, size:, scroll:, border:, html_attributes:), &block
  end

  def dsfr_sidemenu(title:, button: nil, sticky: false, full_height: false, right: false, &block)
    component = Dsfr::SidemenuComponent.new(title:, button:, sticky:, full_height:, right:)
    yield(component) if block_given?
    render component
  end

  def dsfr_pagination
    render Dsfr::PaginationComponent.new(pagy: @pagy)
  end

  def dsfr_tooltip(text, title:, type: :button)
    render Dsfr::TooltipComponent.new(text, title:, type:)
  end

  def dsfr_row_check(record)
    input_id = "row_check_#{record.id}"
    text = t("shared.select_name", name: record.to_s)
    <<-HTML.html_safe
    <th class="fr-cell--fixed fr-enlarge-input" scope="row">
      <div class="fr-checkbox-group fr-checkbox-group--sm" title="#{text}">
        <input type="checkbox" name="id[]" value="#{record.id}" id="#{input_id}" form="table_form" data-fr-row-select="true" data-action="table#toggle" data-table-target="checkbox">
        <label for="#{input_id}" class="fr-label">#{text}</label>
      </div>
    </th>
    HTML
  end

  def dsfr_row_check_all
    input_id = "row_check_all"
    text = t("shared.select_name", name: t("shared.all_lines"))
    <<-HTML.html_safe
    <th class="fr-cell--fixed fr-enlarge-input" role="columnheader">
      <div class="fr-checkbox-group fr-checkbox-group--sm" title="#{text}">
        <input type="checkbox" id="#{input_id}" data-action="table#toggleAll" data-table-target="toggleAll">
        <label for="#{input_id}" class="fr-label">#{text}</label>
      </div>
    </th>
    HTML
  end

  def icon(*icon, fill: true, **options, &block)
    icon = Array.wrap(icon).join("-")
    fill = options[:line] || !fill ? "line" : "fill"
    tag = options[:tag] || :span
    options[:class] = class_names(options[:class], "fr-icon-#{icon}-#{fill}")
    options[:aria] = { hidden: true }.merge(options[:aria] || {})
    text = options.delete(:text)
    content_tag(tag, text, **options, &block)
  end

  def icon_class(*icon, fill: true, **options)
    icon = Array.wrap(icon).join("-")
    fill = options[:line] || !fill ? "line" : "fill"
    side = options[:side].to_s.to_sym.presence_in([:left, :right])
    size = options[:size].to_s.to_sym.presence_in([:sm, :lg])
    btn = (options[:button] || options[:btn])
    btn_style = btn && btn.to_s.to_sym.presence_in([:primary, :secondary, :tertiary, :sort])
    btn_style = "tertiary-no-outline" if btn_style == :tertiary && options[:outline] == false
    link = !btn && side
    class_names(
      options[:class],
      "fr-link" => link,
      "fr-link--#{size}" => link && size,
      "fr-link--icon-#{side}" => link && side,
      "fr-btn" => btn,
      "fr-btn--#{size}" => btn && size,
      "fr-btn--#{btn_style}" => btn_style,
      "fr-btn--icon-#{side}" => btn && side,
      "fr-icon-#{icon}-#{fill}" => icon.present?,
    )
  end

  def link_icon(icon, name = nil, options = {}, html_options = {}, &block)
    html_options, options, name = options, name, block.call if block_given?
    icon_options = html_options.extract!(:fill, :line, :side, :size, :button, :btn, :outline, :class)
    html_options[:class] = icon_class(icon, **icon_options)
    if html_options.delete(:sr_only)
      html_options[:class] += " link--icon-only"
      name = tag.span(class: "fr-sr-only") { name }
    end
    link_to(name, options, html_options)
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

  def aria_sort(param)
    return unless (current_sort = params.dig(:sort, param)&.downcase&.to_sym)

    "aria-sort=#{current_sort == :asc ? :descending : :ascending}"
  end

  def set_focus(selector)
    tag.div(hidden: true, data: { controller: :focus, "focus-selector-value": "##{selector}" })
  end

  def root? = request.path == "/"

  def time_ago(datetime)
    datetime = datetime.in_time_zone if datetime.respond_to?(:in_time_zone)
    time = distance_of_time_in_words_to_now(datetime)
    t("shared.#{ datetime.before?(Time.zone.now) ? :time_ago : :time_until }", time:)
  end

  def use_centered_layout(boxed: true)
    content_for :center_layout, true
    content_for :boxed_layout, boxed
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

  def page_actions(**html_attributes, &block)
    default_class = "fr-btns-group fr-btns-group--inline-md fr-mb-2w"
    html_attributes[:class] = class_names(default_class, html_attributes[:class])

    tag.div(**html_attributes, &block)
  end

  def current_git_commit
    ENV["CONTAINER_VERSION"] || `git show -s --format=%H`
  end
end
