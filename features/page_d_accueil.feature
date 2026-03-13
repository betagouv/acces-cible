# language: fr

# Note : les IDEs et leurs plugins Cucumber sont censés pouvoir gérer
# l'internationalisation et donc les mots-clés en français aussi.

Fonctionnalité: Accueil

  Scénario: Smoke test
    Quand je me rends sur la page d'accueil
    Alors la page contient "Accès cible"

  Scénario: Un agent se connecte pour la première fois
    Sachant que je suis "amanda.rousseau@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Quand je me pro-connecte
    Alors la page contient "Vous êtes maintenant connecté•e."
    Alors l'en-tête contient "Amanda Rousseau"
