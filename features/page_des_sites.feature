# language: fr

Fonctionnalité:

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je clique sur "Ajouter un site"

  Scénario: Un agent peut trier les sites par URL croissantes
    Sachant que je possède un fichier "tmp/sites.csv" qui contient
      """
      url
      https://beta.gouv.fr
      https://www.suresnes.fr
      https://numerique.gouv.fr
      """
    Et que j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Quand je clique sur "Importer"
    Et que je clique sur "Trier par Adresse du site croissant"
    Alors la colonne "Adresse du site" du tableau "Tous les sites" contient dans l'ordre :
      | beta.gouv.fr      |
      | numerique.gouv.fr |
      | suresnes.fr       |
