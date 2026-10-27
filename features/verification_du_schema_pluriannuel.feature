# language: fr

Fonctionnalité: Vérifications du schéma pluriannuel d'accessibilité

  Contexte:
    Sachant que nous sommes en 2026
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je rajoute un site "https://foobar.com/"
    Et que le site "https://foobar.com/" renvoie une réponse HTML normale pour la page d'accueil

  Plan du scénario: le schéma pluriannuel est compris et vérifié
    Sachant que le site "https://foobar.com/" renvoie "<contenu>" pour la déclaration d'accessibilité
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Et que je clique sur "Voir le résultat"
    Alors la vérification "Schéma pluriannuel d'accessibilité" de la carte "Qualité de la déclaration" indique "<résultat>"

    Exemples:
      | contenu                                        | résultat         |
      | schéma pluriannuel d'accessibilité 2020 - 2026 | La période ne doit pas dépasser 3 ans |
      | schéma annuel d'accessibilité 2025 - 2026      | 2025-2026        |
      | schéma plurianneul 1998 2000                   | Absent           |
      | schéma annuel d'accessibilité 1998 - 2000      | Le schéma pluriannuel est obsolète et doit être mis à jour |
      | schéma annuel d'accessibilité 2027 - 2029      | Le schéma pluriannuel doit s'appliquer sur l'année en cours |
      | schéma annuel d'accessibilité 2015 - 2020      | Le schéma pluriannuel est obsolète et doit être mis à jour |
      | schéma bizarre d'accessibilité                 | Absent           |
      | schéma annuel d'accessibilité 0946-0943        | Renseignez des dates contenant l'année en cours |
