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
    Et que l'import est terminé
    Et que je clique sur "Mes évaluations"
    Et que je filtre par étiquette "public"
    Alors la colonne "Site" du tableau "Mes évaluations" contient dans l'ordre :
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
    Et que l'import est terminé
    Et que je clique sur "Mes évaluations"
    Et que je clique sur "Trier par Site croissant"
    Alors la colonne "Site" du tableau "Mes évaluations" contient dans l'ordre :
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
    """
    Et que j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Quand je clique sur "Importer"
    Et que l'import est terminé
    Et que je clique sur "Mes évaluations"
    Et que je clique sur "Trier par Site croissant"
    Alors la colonne "Site" du tableau "Mes évaluations" contient dans l'ordre :
      | alpha.gouv.fr   |
      | beta.gouv.fr    |
      | delta.gouv.fr   |
      | epsilon.gouv.fr |
      | gamma.gouv.fr   |
      | iota.gouv.fr    |
      | kappa.gouv.fr   |
      | lambda.gouv.fr  |
      | psi.gouv.fr     |
      | theta.gouv.fr   |
    Quand je filtre par étiquette "beta"
    Alors la colonne "Site" du tableau "Mes évaluations" contient dans l'ordre :
      | alpha.gouv.fr   |
      | beta.gouv.fr    |
      | delta.gouv.fr   |
      | epsilon.gouv.fr |
    Quand je recherche "a.gouv"
    Alors la colonne "Site" du tableau "Mes évaluations" contient dans l'ordre :
      | alpha.gouv.fr |
      | beta.gouv.fr  |
      | delta.gouv.fr |

  Scénario: Un agent peut voir les sites avec leurs liens et étiquettes
    Sachant que je rajoute un site "https://example1.gouv.fr"
    Et que je rajoute un site "https://example2.gouv.fr"
    Et que le site "https://example1.gouv.fr" a les étiquettes "production, public"
    Quand je clique sur "Mes évaluations"
    Alors la page contient un tableau
    Et la page contient un lien vers "https://example1.gouv.fr"
    Et la page contient un lien vers "https://example2.gouv.fr"
    Et la page contient "production"
    Et la page contient "public"

  Scénario: Un agent voit les résultats de l'évaluation dans les colonnes par défaut
    Sachant que je possède un site "https://example.gouv.fr" avec des données
    Quand je clique sur "Mes évaluations"
    Alors la colonne "Site" du tableau "Mes évaluations" contient dans l'ordre :
      | example.gouv.fr |
    Et le tableau "Mes évaluations" contient les colonnes :
      | Taux d'accessibilité déclaré     |
      | Niveau d'accessibilité déclaré   |
      | Respect des obligations légales  |
      | Qualité de la déclaration        |
      | Évaluateur                       |
      | Organisation                     |
      | Étiquettes                       |
    Et le tableau "Mes évaluations" ne contient pas la colonne "Site joignable"

  Scénario: Un agent peut choisir les colonnes affichées
    Sachant que je possède un site "https://example.gouv.fr" avec des données
    Quand je clique sur "Mes évaluations"
    Alors le tableau "Mes évaluations" contient la colonne "Évaluateur"
    Et le tableau "Mes évaluations" ne contient pas la colonne "Auditeur"
    Quand je coche "Auditeur"
    Et que je décoche "Évaluateur"
    Et que je clique sur le premier lien ou bouton "Appliquer"
    Et que je rafraîchis la page
    Alors le tableau "Mes évaluations" contient la colonne "Auditeur"
    Et le tableau "Mes évaluations" ne contient pas la colonne "Évaluateur"

  Scénario: Un agent peut afficher toutes les colonnes
    Sachant que je possède un site "https://example.gouv.fr" avec des données
    Quand je clique sur "Mes évaluations"
    Et que je coche toutes les cases
    Et que je clique sur le premier lien ou bouton "Appliquer"
    Alors le tableau "Mes évaluations" contient les colonnes :
      | Site                                                |
      | Taux d'accessibilité déclaré                        |
      | Niveau d'accessibilité déclaré                       |
      | Respect des obligations légales                     |
      | Qualité de la déclaration                            |
      | Déclaration d'accessibilité                          |
      | Mention d'accessibilité                              |
      | Schéma pluriannuel                                   |
      | Plan d'action                                        |
      | Site joignable                                       |
      | Évaluateur                                           |
      | Organisation                                         |
      | Étiquettes                                           |
      | Hébergement de la déclaration                        |
      | Date de déclaration                                  |
      | Référentiel                                          |
      | Auditeur                                             |
      | Article de loi                                       |
      | Adresse email de contact (ou formulaire de contact)  |
      | Format de la déclaration                             |
      | Schéma pluriannuel (qualité)                         |
      | Plan d'action (qualité)                              |
      | Résultat des tests auto RGAA                         |
      | Tests auto RGAA applicables                          |
      | Tests auto RGAA réussis                              |
      | Tests auto non applicables                           |

  Scénario: Un agent voit un message quand aucun site n'existe
    Quand je clique sur "Mes évaluations"
    Alors la page contient un tableau
    Et la page contient "Aucune évaluation à afficher."
