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
    Quand je me rends sur la page d'accueil
    Alors la page contient "Bonjour Amanda Rousseau"

  Règle: La page d'accueil affiche les statistiques

    Contexte:
      Sachant que je suis "amanda.rousseau@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
      Et que je me pro-connecte
      Et que je rajoute un CSV de 3 sites
      Et que je rajoute un site "https://foobar.com/"
      Et que je clique sur "Lancer une évaluation"

    Scénario: Un agent connecté voit ses statistiques
      Quand je me rends sur la page d'accueil
      Alors la carte "Évaluations lancées" indique "5 dont 5 cette semaine"
      Et la carte "Sites évalués" indique "4 sites distincts"

    Scénario: Un agent non connecté voit les statistiques globales
      Quand je me déconnecte
      Et je me rends sur la page d'accueil
      Alors la carte "Évaluations lancées" indique "5 dont 5 cette semaine"
      Et la carte "Sites évalués" indique "4 sites distincts"
