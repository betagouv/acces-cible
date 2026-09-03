# language: fr

Fonctionnalité: Page du site

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte

  Scénario: Un agent peut voir les détails d'un site
    Sachant que je rajoute un site "https://beta.gouv.fr"
    Alors la page contient "https://beta.gouv.fr"
    Et la page contient "Historique des vérifications"

  # TODO: réécrire après implementation de l'import CSV
  # Scénario: Un agent peut accéder aux étiquettes depuis la page du site
    # Sachant que je possède un fichier "tmp/sites.csv" qui contient
      # """
      # url;nom;tags
      # https://beta.gouv.fr;beta.gouv.fr;éticouette
      # """
    # Et que le site "https://beta.gouv.fr/" renvoie une réponse HTML normale pour la page d'accueil
    # Et que le site "https://beta.gouv.fr/" renvoie une réponse HTML normale pour la déclaration d'accessibilité
    # Et que j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    # Quand je clique sur "Importer"
    # Et que l'import est terminé
    # Et que je clique sur "Tous les sites"
    # Et que je clique sur "Voir la fiche de beta.gouv.fr"
    # Et que je clique sur "Étiquette éticouette"
    # Alors la page est titrée "éticouette"

# TODO: Implement tags edit action when design will be there.
#  Scénario: Un agent peut modifier les étiquettes d'un site
#    Sachant que je rajoute un site "https://example.gouv.fr"
#    Et que le site "https://example.gouv.fr" a les étiquettes "production, public"
#    Quand je clique sur "Modifier les étiquettes"
#    Et que je décoche "production"
#    Et que je remplis "Nouvelle étiquette" avec "éticouette"
#    Et que je clique sur "Enregistrer"
#    Alors la page contient "Étiquettes modifiées"
#    Et la page contient "public"
#    Et la page contient "éticouette"
#    Et la page ne contient pas "production"

  Scénario: Un agent peut voir les étiquettes associées à un site
    Sachant que je rajoute un site "https://example.gouv.fr"
    Et que le site "https://example.gouv.fr" a les étiquettes "production, public"
    Quand je clique sur "Tous les sites"
    Et que je clique sur "Voir la fiche de example.gouv.fr"
    Alors la page contient un lien vers "https://example.gouv.fr"
    Et la page contient "production"
    Et la page contient "public"

  Scénario: Un agent peut voir l'historique des audits
    Sachant que je rajoute un site "https://example.gouv.fr"
    Et que je clique sur "Relancer une évaluation"
    Alors la page contient "Historique des vérifications (2)"
    Alors la page contient "La plus récente"
