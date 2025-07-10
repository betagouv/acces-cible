# language: fr

Fonctionnalité: Ajout d'un site
  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je clique sur "Ajouter un site"

  Scénario: Un agent peut ajouter un site manuellement
    Sachant que je remplis "Adresse du site" avec "https://beta.gouv.fr"
    Et que je remplis "Nom du site" avec "beta.gouv.fr"
    Quand je clique sur "Ajouter"
    Alors la page contient "Site ajouté"

  Scénario: Un agent peut ajouter un CSV de sites
    Sachant que je possède un fichier "tmp/sites.csv" qui contient
      """
      url
      https://beta.gouv.fr
      https://numerique.gouv.fr
      """
    Et que j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Quand je clique sur "Importer"
    Alors la page contient "2 sites ajoutés"
