module IconHelper
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

  def aria_sort(param)
    return unless (current_sort = params.dig(:sort, param)&.downcase&.to_sym)

    "aria-sort=#{current_sort == :asc ? :descending : :ascending}"
  end
end
