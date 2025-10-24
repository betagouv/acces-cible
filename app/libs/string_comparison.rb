require "did_you_mean/levenshtein"

module StringComparison
  DEFAULT_OPTIONS = {
    ignore_case: false,
    partial: false,
    fuzzy: 1.0
  }.freeze

  module_function

  # Return the similarity ratio between two strings (from 0.0, different, to 1.0, identical)
  def similarity_ratio(str1, str2, options = {})
    raise ArgumentError.new("Fuzzy option must be greater than 0.") if options[:fuzzy]&.zero?
    raise ArgumentError.new("Fuzzy option must be 1.0 maximum") if options[:fuzzy].to_f > 1.0

    str1, str2 = str1.to_s, str2.to_s
    return 0.0 if str1.empty? || str2.empty?

    options = DEFAULT_OPTIONS.merge(options)
    str1, str2 = str1.downcase, str2.downcase if options[:ignore_case]
    return 1.0 if str1 == str2

    max_len = [str1.length, str2.length].max
    distance = DidYouMean::Levenshtein.distance(str1, str2)
    1.0 - (distance.to_f / max_len)
  end

  def match?(str1, str2, options = {})
    ratio = DEFAULT_OPTIONS.merge(options)[:fuzzy]
    similarity_ratio(str1, str2, options) >= ratio
  end
end
