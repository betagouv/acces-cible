# language: fr

Fonctionnalité:

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je clique sur "Ajouter un site"

  Scénario: Un agent peut filtrer les sites par nom de tag
    Sachant que je possède un fichier "tmp/sites.csv" qui contient
      """
      url;tags
      https://beta.gouv.fr;beta
      https://numerique.gouv.fr;gouv,public
      https://www.suresnes.fr;public
      """
    Et que j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Quand je clique sur "Importer"
    Et que je filtre par étiquette "public"
    Alors la colonne "Adresse du site" du tableau "Tous les sites" contient dans l'ordre :
      | suresnes.fr       |
      | numerique.gouv.fr |

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

  Scénario: Un agent peut combiner tri, filtre par tag et recherche
    Sachant que je possède un fichier "tmp/sites.csv" qui contient
      """
      url;tags
      https://alpha.gouv.fr;beta
      https://beta.gouv.fr;beta
      https://gamma.gouv.fr;public
      https://delta.gouv.fr;public,beta
      https://epsilon.gouv.fr;beta
      https://theta.gouv.fr;public
      https://iota.gouv.fr;public
      https://kappa.gouv.fr;public
      https://lambda.gouv.fr;public
      https://psi.gouv.fr;public
      https://omega.gouv.fr;public
      """
    Et que j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Quand je clique sur "Importer"
    Et que je clique sur "Trier par Adresse du site croissant"
    Alors la colonne "Adresse du site" du tableau "Tous les sites" contient dans l'ordre :
      | alpha.gouv.fr   |
      | beta.gouv.fr    |
      | delta.gouv.fr   |
      | epsilon.gouv.fr |
      | gamma.gouv.fr   |
      | iota.gouv.fr    |
      | kappa.gouv.fr   |
      | lambda.gouv.fr  |
      | omega.gouv.fr   |
      | psi.gouv.fr     |
      | theta.gouv.fr   |
    Quand je filtre par étiquette "beta"
    Alors la colonne "Adresse du site" du tableau "Tous les sites" contient dans l'ordre :
      | alpha.gouv.fr   |
      | beta.gouv.fr    |
      | delta.gouv.fr   |
      | epsilon.gouv.fr |
    Quand je recherche "a.gouv"
    Alors la colonne "Adresse du site" du tableau "Tous les sites" contient dans l'ordre :
      | alpha.gouv.fr |
      | beta.gouv.fr  |
      | delta.gouv.fr |
