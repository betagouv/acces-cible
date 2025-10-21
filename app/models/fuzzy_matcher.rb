# Wraps a string and exposes a match? method
# Allows passing a FuzzyMatcher instead of a Regex
class FuzzyMatcher < Data.define(:target_text)
  OPTIONS = { ignore_case: true, fuzzy: 0.85 }.freeze

  def match?(text)
    StringComparison.similar?(text, target_text, **OPTIONS)
  end
end
