module AccessibilityDeclarationHeadings
  EXPECTED_HEADINGS = [
    [2, "État de conformité"],
    [3, "Résultats des tests"],
    [2, "Contenus non accessibles"],
    [3, "Non-conformités"],
    [3, "Dérogations pour charge disproportionnée"],
    [3, "Contenus non soumis à l'obligation d'accessibilité"],
    [2, "Établissement de cette déclaration d'accessibilité"],
    [3, "Technologies utilisées pour la réalisation du site"],
    [3, "Environnement de test"],
    [3, "Outils pour évaluer l'accessibilité"],
    [3, "Pages du site ayant fait l'objet de la vérification de conformité"],
    [2, "Retour d'information et contact"],
    [2, "Voies de recours"],
  ].freeze

  def self.expected_heading_titles
    EXPECTED_HEADINGS.map { |_, heading_title| heading_title }
  end
end
