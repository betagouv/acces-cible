module PageHelper
  TRUNCATE_LENGTH = 50

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

  def use_centered_layout(boxed: true)
    content_for :center_layout, true
    content_for :boxed_layout, boxed
  end

  def page_actions(**html_attributes, &block)
    default_class = "fr-btns-group fr-btns-group--inline-md fr-mb-2w"
    html_attributes[:class] = class_names(default_class, html_attributes[:class])

    tag.div(**html_attributes, &block)
  end
end
