# language: fr

Fonctionnalité: Ajout d'un site

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je clique sur "Lancer une évaluation"
    Et que je choisis "Saisir des adresses"
    Et que je clique sur "Continuer"

  Scénario: Un agent peut ajouter un site manuellement
    Sachant que je remplis "Adresse du site" avec "beta.gouv.fr"
    Quand je clique sur "Continuer"
    Alors la page contient "Adresse du site n'est pas valide"
    Quand je remplis "Adresse du site" avec "https://beta.gouv.fr/"
    Et que je clique sur "Continuer"
    Et que je clique sur "Continuer"
    Et que je clique sur "Lancer l'évaluation"
    Alors la page contient "Évaluation lancée. Les résultats arriveront dans quelques minutes."

  # TODO: réécrire après implementation de l'import CSV
  # Scénario: Un agent peut ajouter un CSV de sites
    # Sachant que je possède un fichier "tmp/sites.csv" qui contient
      # """
      # url
      # https://beta.gouv.fr
      # https://numerique.gouv.fr
    # """
    # Et que j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    # Quand je clique sur "Importer"
    # Alors la page contient "L'import du fichier CSV a commencé. 2 sites seront ajoutés progressivement."
