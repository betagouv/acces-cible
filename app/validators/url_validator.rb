class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    begin
      uri = URI.parse(value)
      return if uri.host.present? && uri.scheme.match?(/^https?$/)
    rescue URI::InvalidURIError
    end
    record.errors.add(attribute, :invalid)
  end
end
