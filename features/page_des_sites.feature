# language: fr

Fonctionnalité:

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que le site "https://beta.gouv.fr/" renvoie des réponses normales
    Et que le site "https://numerique.gouv.fr/" renvoie des réponses normales
    Et que le site "https://www.suresnes.fr/" renvoie des réponses normales
    Et que je possède un fichier "tmp/sites.csv" qui contient
      """
      url;tags
      https://beta.gouv.fr;beta
      https://numerique.gouv.fr;gouv,public
      https://www.suresnes.fr;public
      """
    Et que je choisis "Ajouter un site" dans le menu principal
    Et que j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Et que je clique sur "Importer"
    Et que toutes les tâches de fond sont terminées
    Et que je recharge la page

  Scénario: Un agent peut filtrer les sites par nom de tag
    Quand je filtre par étiquette "public"
    Alors la colonne "Adresse du site" du tableau "Tous les sites" contient dans l'ordre :
      | suresnes.fr       |
      | numerique.gouv.fr |

  Scénario: Un agent peut trier les sites par URL croissantes
    Quand je clique sur "Trier par Adresse du site croissant"
    Alors la colonne "Adresse du site" du tableau "Tous les sites" contient dans l'ordre :
      | beta.gouv.fr      |
      | numerique.gouv.fr |
      | suresnes.fr       |

  Scénario: Un agent peut voir les statuts de vérification pour chaque site
    Sachant que je possède un site "https://example.gouv.fr" avec des données
    Quand je clique sur "Tous les sites"
    Et la page contient toutes les vérifications du site "https://example.gouv.fr" avec le préfixe "sites_table"
