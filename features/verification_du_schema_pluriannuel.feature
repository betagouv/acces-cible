# language: fr

Fonctionnalité: Vérifications d'un site
  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je rajoute un site "https://foobar.com/"
    Et que le site "https://foobar.com/" renvoie une réponse HTML normale pour la page d'accueil

  Plan du scénario: le schéma pluriannuel est compris et vérifié
    Sachant que le site "https://foobar.com/" renvoie "<contenu>" pour la déclaration d'accessibilité
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Alors la section "Schéma pluriannuel d'accessibilité" indique "<résultat>"

  Exemples:
      | contenu                                   | résultat   |
      | schéma pluriannuel 2020 - 2026            | Non trouvé |
      | schéma pluriannuel 2020 - 2026            | Non trouvé |
      | schéma plurianneul 1998 2000              | Non trouvé |
      | schéma annuel d'accessibilité 2025 - 2026 | 2025-2026  |
      | schéma bizarre d'accessibilité            | Non trouvé |
      | schéma annuel d'accessibilité 1998 - 2000 | 1998-2000  |
