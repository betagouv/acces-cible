module Checks
  class AccessibilityPageHeading < Check
    PRIORITY = 22
    REQUIREMENTS = [:find_accessibility_page]
    EXPECTED_HEADINGS = [
      [1, "Déclaration d'accessibilité"],
        [2, "État de conformité"],
          [3, "Résultats des tests"],
        [2, "Contenus non accessibles"],
          [3, "Non-conformités"],
          [3, "Dérogations pour charge disproportionnée"],
          [3, "Contenus non soumis à l'obligation d'accessibilité "],
        [2, "Établissement de cette déclaration d'accessibilité"],
          [3, "Technologies utilisées pour la réalisation du site"],
          [3, "Environnement de test"],
          [3, "Outils pour évaluer l'accessibilité"],
          [3, "Pages du site ayant fait l'objet de la vérification de conformité"],
        [2, "Retour d'information et contact"],
        [2, "Voies de recours"],
    ].freeze
    COMPARISON_OPTIONS = { partial: true, fuzzy: 0.65, ignore_case: true }.freeze

    delegate :expected_headings, to: :class

    class << self
      def expected_headings = EXPECTED_HEADINGS
    end

    store_accessor :data, :page_headings, :comparison

    def tooltip? = failed? || comparison.empty?
    def comparison = @comparison ||= super&.map { PageHeadingStatus.new(*it) } || []
    def total = expected_headings.count
    def failures = comparison.filter { it.error? }
    def score = comparison.empty? ? 0 : (total - failures.count) / total.to_f * 100
    def human_explanation = human(:explanation, total:, count: failures.count, error: failures.first.message)

    def custom_badge_text = "#{total - failures.count}/#{total}"
    def custom_badge_status
      case score
      when 90..100 then :success
      when 60..90  then :warning
      else              :error
      end
    end

    private

    def page = @page ||= Page.new(url: audit.find_accessibility_page.url) # TODO: Refactor to stop breaking the law of Demeter

    def analyze!
      {
        page_headings: page.heading_levels,
        comparison: compare_headings
      }
    end

    def indexed_expected_headings
      @indexed_expected_headings ||= expected_headings.each_with_index.map { |(level, heading), index| [index, heading, level] }
    end

    def indexed_page_headings
      @indexed_page_headings ||= page_headings.each_with_index.map { |(level, heading), index| [index, heading, level] }
    end

    def compare_headings
      return expected_headings.map { |level, heading| [heading, level, :missing, nil] } unless page_headings

      # Two-pass approach: first match all headings, then determine status
      expected_to_actual = {}

      # First pass: find best matches for each expected heading without order constraints
      indexed_expected_headings.each do |(expected_index, expected_heading, expected_level)|
        best_match = find_unconstrained_best_match(expected_heading, expected_to_actual.values)
        expected_to_actual[expected_index] = best_match if best_match
      end

      # Second pass: determine status based on matched ordering
      last_matched_index = -1
      indexed_expected_headings.map do |(expected_index, expected_heading, expected_level)|
        if match_data = expected_to_actual[expected_index]
          page_heading, heading_level, original_index = match_data

          # Determine status
          status = if original_index < last_matched_index
            :incorrect_order
          elsif heading_level != expected_level + first_heading_offset
            :incorrect_level
          else
            :ok
          end

          last_matched_index = original_index

          [expected_heading, expected_level, status, page_heading]
        else
          [expected_heading, expected_level, :missing, nil]
        end
      end
    end

    def find_unconstrained_best_match(expected_heading, already_matched)
      best_match = nil
      best_score = 0

      # Extract just the already matched indices
      matched_indices = already_matched.map { |match| match && match[2] }.compact

      indexed_page_headings.each do |(index, page_heading, level)|
        next if matched_indices.include?(index)

        score = similarity_ratio(expected_heading, page_heading)

        if score >= COMPARISON_OPTIONS[:fuzzy] && score > best_score
          best_score = score
          best_match = [page_heading, level, index]
        end
      end

      best_match
    end

    def find_best_match(expected_heading, candidates)
      candidates
        .map { |index, heading, level| [heading, level, index, similarity_ratio(expected_heading, heading)] }
        .select { |_, _, _, score| score >= COMPARISON_OPTIONS[:fuzzy] }
        .max_by { |_, _, _, score| score }
        &.first(3)
    end

    def first_heading_offset
      @first_heading_offset ||= begin
        if page_headings.empty?
          0
        else
          matches = []

          indexed_expected_headings.each do |_, expected_heading, expected_level|
            indexed_page_headings.each do |_, page_heading, page_level|
              score = similarity_ratio(expected_heading, page_heading, partial: false)

              if score >= COMPARISON_OPTIONS[:fuzzy]
                matches << [expected_level, page_level, score]
              end
            end
          end
          return 0 if matches.empty?

          expected_level, page_level, _ = matches.max_by { |_, _, score| score }
          page_level - expected_level
        end
      end
    end

    def similarity_ratio(a, b, options = {})
      StringComparison.similarity_ratio(a, b, **COMPARISON_OPTIONS.merge(options))
    end

    def similar?(a, b, options = {})
      StringComparison.similar?(a, b, **COMPARISON_OPTIONS)
    end
  end
end
