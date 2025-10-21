require "did_you_mean/levenshtein"

module StringComparison
  DEFAULT_OPTIONS = {
    ignore_case: false,
    partial: false,
    fuzzy: 1.0
  }.freeze

  module_function

  def match?(str1, str2, options = {})
    raise ArgumentError.new("Fuzzy option must be greater than 0.") if options[:fuzzy]&.zero?
    return false if str1.nil? || str2.nil?

    str1, str2 = str1.to_s, str2.to_s
    options = DEFAULT_OPTIONS.merge(options)
    str1, str2 = str1.downcase, str2.downcase if options[:ignore_case]

    if options[:partial]
      partial_match?(str1, str2, options)
    else
      exact_match?(str1, str2, options)
    end
  end

  # Return the similarity ratio between two strings (from 0.0, different, to 1.0, identical)
  def similarity_ratio(str1, str2, options = {})
    str1, str2 = str1.to_s, str2.to_s
    return 0.0 if str1.empty? || str2.empty?

    options = DEFAULT_OPTIONS.merge(options)
    str1, str2 = str1.downcase, str2.downcase if options[:ignore_case]
    return 1.0 if str1 == str2

    max_len = [str1.length, str2.length].max
    if max_len.zero?
      0.0
    else
      distance = DidYouMean::Levenshtein.distance(str1, str2)
      1.0 - (distance.to_f / max_len)
    end
  end

  def exact_match?(str1, str2, options)
    if fuzzy_matching?(options)
      similarity_ratio(str1, str2, options) >= options[:fuzzy]
    else
      str1 == str2
    end
  end

  def partial_match?(str1, str2, options)
    if fuzzy_matching?(options)
      max_substring_similarity(str1, str2, options) >= options[:fuzzy]
    else
      str1.include?(str2) || str2.include?(str1)
    end
  end

  def max_substring_similarity(str1, str2, options)
    str1, str2 = str2, str1 if str1.length < str2.length # Use the longest string as str1
    return 1.0 if str1.include?(str2)

    # Use a windowing approach for long strings
    max_similarity = 0.0
    if str1.length < 100
      (0..str1.length - str2.length).each do |i|
        substring = str1[i, str2.length]
        similarity = similarity_ratio(substring, str2, options)
        max_similarity = [max_similarity, similarity].max
      end
    else
      step = [str1.length / 20, 1].max
      (0..str1.length - str2.length).step(step).each do |i|
        substring = str1[i, str2.length]
        similarity = similarity_ratio(substring, str2, options)
        max_similarity = [max_similarity, similarity].max
      end
    end

    max_similarity
  end

  def fuzzy_matching?(options)
    options[:fuzzy] && options[:fuzzy] < 1.0
  end
end
