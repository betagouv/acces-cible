# language: fr

Fonctionnalité: Vérifications du plan d'accessibilité

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je rajoute un site "https://foobar.com/"
    Et que le site "https://foobar.com/" renvoie une réponse HTML normale pour la page d'accueil

  Plan du scénario: le plan d'accessibilité est compris et vérifié
    Sachant que le site "https://foobar.com/" renvoie "<contenu>" pour la déclaration d'accessibilité
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Et que je clique sur "Voir le résultat"
    Alors la vérification "Plan d'action" de la carte "Qualité de la déclaration" indique "<résultat>"

    Exemples:
      | contenu                                 | résultat              |
      | plan annuel d'accessibilité 2020 - 2024 | Année(s) invalide(s)  |
      | plan annuel d'accessibilité 2024 - 2025 | 2024-2025             |
      | plan annuel 2024 - 2025                 | 2024-2025             |
      | plan d'action 2024 - 2025               | 2024-2025             |
      | plan d'action 1998 - 2000               | Année(s) invalide(s)  |
      | plan d'action 0946                      | Année(s) invalide(s)  |
      | plann d'accessibilité 2024 - 2025       | Absent                |
      | plan d'accessibilité                    | Absent                |
