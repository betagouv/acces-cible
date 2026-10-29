# language: fr

Fonctionnalité: Filtrage des évaluations depuis la modale "Plus de filtres"

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je possède un fichier "tmp/sites.csv" qui contient
      """
      url
      https://alpha.gouv.fr
      https://beta.gouv.fr
      """
    Et que le site "https://alpha.gouv.fr/" ne trouve pas de page d'accessibilité

  Scénario: Un agent peut filtrer les évaluations par niveau d'accessibilité déclaré
    Sachant que le site "https://alpha.gouv.fr/" renvoie "<p>Accessibilité : totalement conforme</p>" pour la page d'accueil
    Et que le site "https://beta.gouv.fr/" renvoie "<p>Accessibilité : non conforme</p>" pour la page d'accueil
    Et que j'importe le fichier CSV "tmp/sites.csv"
    Et que toutes les tâches de fond sont terminées
    Et que je clique sur "Mes évaluations"
    Quand je clique sur "Plus de filtres"
    Et que je choisis "Totalement conforme" pour le filtre "Niveau d'accessibilité déclaré"
    Et que je clique sur "Filtrer"
    Alors la colonne "Site" du tableau "Mes évaluations" contient dans l'ordre :
      | alpha.gouv.fr |

  Scénario: Un agent peut filtrer les évaluations sans mention d'accessibilité
    Sachant que le site "https://alpha.gouv.fr/" renvoie "<p>Accessibilité : non conforme</p>" pour la page d'accueil
    Et que le site "https://beta.gouv.fr/" renvoie "<p>Bienvenue</p>" pour la page d'accueil
    Et que j'importe le fichier CSV "tmp/sites.csv"
    Et que toutes les tâches de fond sont terminées
    Et que je clique sur "Mes évaluations"
    Quand je clique sur "Plus de filtres"
    Et que je choisis "Absente" pour le filtre "Mention d'accessibilité"
    Et que je clique sur "Filtrer"
    Alors la colonne "Site" du tableau "Mes évaluations" contient dans l'ordre :
      | beta.gouv.fr |
