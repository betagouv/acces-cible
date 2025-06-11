module DsfrFormBuilderExtension
  # Override to use `value`, otherwise checkbox labels have an invalid `for`
  def dsfr_label_with_hint(attribute, opts = {})
    opts[:class] = "fr-label #{opts[:class]}".strip
    label(attribute, **opts.except(:name, :checked, :required, :label, :id).merge(for: opts[:id])) do
      @template.safe_join([
        label_value(attribute, opts),
        (required_tag if opts[:required] && display_required_tags),
        hint_tag(opts[:hint])
      ])
    end
  end

  # Override to add support for `inline` option, and prevent DSFR-specific options from ending up as check_box attributes
  def dsfr_check_box(attribute, opts = {}, checked_value = "1", unchecked_value = "0")
    @template.content_tag(:div, class: "fr-fieldset__element #{'fr-fieldset__element--inline' if opts.delete(:inline)}") do
      @template.content_tag(:div, class: "fr-checkbox-group") do
        @template.safe_join([
          check_box(attribute, opts.except(:label, :hint), checked_value, unchecked_value),
          dsfr_label_with_hint(attribute, opts)
        ])
      end
    end
  end

  # New method, to be merged back into dsfr-form-builder
  def dsfr_collection_check_boxes(attribute, collection, value_method, text_method, options = {}, html_options = {})
    legend = @template.safe_join([
      options.delete(:legend) || @object.class.human_attribute_name(attribute),
      hint_tag(options.delete(:hint))
    ])
    name = options.delete(:name) || "#{@object_name}[#{attribute}][]"
    html_options[:class] = ["fr-fieldset", html_options[:class]].compact.join(" ")
    @template.content_tag(:fieldset, **html_options) do
      @template.safe_join([
        @template.content_tag(:legend, legend, class: "fr-fieldset__legend--regular fr-fieldset__legend"),
        @template.hidden_field_tag(name, "", id: nil),
        collection.map do |item|
          value = item.send(value_method)
          checkbox_options = {
            name: name,
            value: value,
            id: field_id(attribute, value),
            label: item.send(text_method),
            inline: options[:inline],
            checked: selected?(attribute, value),
            include_hidden: false
          }
          dsfr_check_box(attribute, checkbox_options, value, "")
        end
      ])
    end
  end

  private

  def selected?(method, value)
    return unless @object.respond_to?(method)

    (@object.send(method) || []).include?(value)
  end
end

Dsfr::FormBuilder.prepend(DsfrFormBuilderExtension)
