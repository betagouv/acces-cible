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
    COMPARISON_OPTIONS = { partial: false, fuzzy: 0.75, ignore_case: true }.freeze

    store_accessor :data, :page_headings, :comparison

    def comparison = @comparison ||= super&.map { |expected, status, heading| [expected, status.to_s.inquiry, heading] } || {}
    def discrepancies = comparison.filter { |_expected, status, _actual| !status.ok? }
    def found_all? = discrepancies.count.zero?
    def score = comparison.empty? ? 0 : (comparison.count - discrepancies.count) / comparison.count.to_f * 100

    private

    def custom_badge_text = helpers.number_to_percentage(score, precision: 2, strip_insignificant_zeros: true)
    def custom_badge_status
      case score
      when 90..100 then :success
      when 60..90  then :warning
      else              :error
      end
    end

    def page = @page ||= Page.new(url: audit.find_accessibility_page.url) # TODO: Refactor to stop breaking the law of Demeter

    def analyze!
      {
        page_headings: page.heading_levels,
        comparison: compare_headings
      }
    end

    def indexed_expected_headings
      @indexed_expected_headings ||= EXPECTED_HEADINGS.each_with_index.map { |(level, heading), index| [index, heading, level] }
    end

    def indexed_page_headings
      @indexed_page_headings ||= page_headings.each_with_index.map { |(level, heading), index| [index, heading, level] }
    end

    def compare_headings
      return EXPECTED_HEADINGS.map { |_, heading| [heading, :missing, nil] } unless page_headings

      last_matched_index = -1

      indexed_expected_headings.map do |(expected_index, expected_heading, expected_level)|
        if (heading_data = best_matches[expected_index])
          page_heading, heading_level, original_index = heading_data

          status = if original_index < last_matched_index
            :incorrect_order
          elsif heading_level != expected_level + first_heading_offset
            :incorrect_level
          else
            :ok
          end
          last_matched_index = original_index

          [expected_heading, status, page_heading]
        else
          [expected_heading, :missing, nil]
        end
      end
    end

    def best_matches
      @best_matches ||= begin
        matches = {}
        matched_indices = []

        indexed_expected_headings.map do |(expected_index, expected_heading, expected_level)|
          best_match = best_match_for(expected_heading, matched_indices)

          if best_match
            matches[expected_index] = best_match
            matched_indices << best_match[2]
          end
        end

        matches
      end
    end

    def best_match_for(expected_heading, matched_indices)
      best_match = nil
      best_score = 0

      indexed_page_headings.each do |(index, page_heading, level)|
        next if matched_indices.include?(index)

        is_similar = similar?(expected_heading, page_heading)
        score = ratio(expected_heading, page_heading)

        if is_similar && score > best_score
          best_score = score
          best_match = [page_heading, level, index]
        end
      end

      best_match
    end

    def first_heading_offset
      @first_heading_offset ||= begin
        if page_headings.empty?
          0
        else
          matches = []

          indexed_expected_headings.each do |_, expected_heading, expected_level|
            indexed_page_headings.each do |_, page_heading, page_level|
              score = ratio(expected_heading, page_heading)

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

    def ratio(a, b, options = {})
      StringComparison.similarity_ratio(a, b, **COMPARISON_OPTIONS.merge(options))
    end

    def similar?(a, b)
      StringComparison.similar?(a, b, **COMPARISON_OPTIONS)
    end
  end
end
