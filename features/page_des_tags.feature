# language: fr

Fonctionnalité: Page des étiquettes

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je clique sur "Ajouter un site"
    Sachant que je possède un fichier "tmp/sites.csv" qui contient
      """
      url;tags
      https://beta.gouv.fr;beta
      https://numerique.gouv.fr;gouv,secret
      https://www.suresnes.fr;secret
      """
    Et que j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Quand je clique sur "Importer"
    Et que l'import est terminé
    Et que je clique sur "Toutes les étiquettes"

  Scénario: Un agent peut voir les sites associés à un tag depuis la page des tags
    Et que je clique sur "Sites avec l'étiquette secret (2)"
    Alors la colonne "Adresse du site" du tableau "Tous les sites" contient dans l'ordre :
      | suresnes.fr       |
      | numerique.gouv.fr |

  Scénario: Un agent peut voir les sites associés à un tag sur sa page
    Et que je clique sur "secret"
    Et que je clique sur "Sites avec l'étiquette secret (2)"
    Alors la colonne "Adresse du site" du tableau "Tous les sites" contient dans l'ordre :
      | suresnes.fr       |
      | numerique.gouv.fr |
