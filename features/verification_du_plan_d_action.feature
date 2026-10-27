# language: fr

Fonctionnalité: Vérifications du plan d'accessibilité

  Contexte:
    Sachant que nous sommes en 2026
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
      | plan annuel d'accessibilité 2025       | Le plan d'action est obsolète et doit être mis à jour |
      | plan d'action 2027                      | Le plan d'action doit faire référence à l'année en cours |
      | plan annuel 2025 - 2028                 | La période ne doit pas dépasser 2 ans |
      | plan annuel d'accessibilité 2024 - 2025 | 2024-2025             |
      | plan annuel 2024 - 2025                 | 2024-2025             |
      | plan d'action 2024 - 2025               | 2024-2025             |
      | plan annuel d'accessibilité 2020 - 2024 | Le plan d'action est obsolète et doit être mis à jour |
      | plan d'action 0946                      | Renseignez des dates contenant l'année en cours |
      | plann d'accessibilité 2024 - 2025       | Absent                |
      | plan d'accessibilité                    | Absent                |
