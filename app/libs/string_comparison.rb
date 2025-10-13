require "did_you_mean/levenshtein"

module StringComparison
  DEFAULT_OPTIONS = {
    ignore_case: false,
    partial: false,
    fuzzy: 1.0
  }.freeze

  module_function

  def similar?(str1, str2, options = {})
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

    if options[:partial]
      partial_match_score(str1, str2)
    else
      levenshtein_similarity(str1, str2)
    end
  end

  def levenshtein_similarity(str1, str2)
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
      partial_match_score(str1, str2) >= options[:fuzzy]
    else
      str1.include?(str2) || str2.include?(str1)
    end
  end

  def partial_match_score(str1, str2)
    str1, str2 = str2, str1 if str1.length < str2.length

    best_score = if str1.include?(str2)
      1.0
    else
      max_fuzzy_substring_match(str1, str2)
    end

    # Penalize length differences
    length_ratio = str2.length.to_f / str1.length
    best_score * Math.sqrt(length_ratio)
  end

  def max_fuzzy_substring_match(str1, str2)
    overlapping_substrings(str1, str2.length).map do |substring|
      levenshtein_similarity(substring, str2)
    end.max || 0.0
  end

  def overlapping_substrings(str, length)
    return [str] if str.length == length

    max_shift = str.length - length
    # Check every position for short strings, sample for long strings
    shift = max_shift < 200 ? 1 : [length / 2, 1].max

    (0..max_shift).step(shift).map do |position|
      str[position, length]
    end
  end

  def fuzzy_matching?(options)
    options[:fuzzy] && options[:fuzzy] < 1.0
  end
end
