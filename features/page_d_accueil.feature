# language: fr

# Note : les IDEs et leurs plugins Cucumber sont censés pouvoir gérer
# l'internationalisation et donc les mots-clés en français aussi.

Fonctionnalité: Accueil
  Scénario: Smoke test
    Quand je me rends sur la page d'accueil
    Alors la page contient "Accès cible"

  Scénario: Un agent se connecte pour la première fois
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Alors la page contient "Ajouter un site"
