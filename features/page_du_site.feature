# language: fr

Fonctionnalité: Page du site

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je clique sur "Ajouter un site"

  Scénario: Un agent peut voir les détails d'un site
    Sachant que je remplis "Adresse du site" avec "https://beta.gouv.fr"
    Et que je remplis "Nom du site" avec "beta.gouv.fr"
    Quand je clique sur "Ajouter"
    Alors la page contient "Site ajouté"
    Et la page contient "https://beta.gouv.fr"
    Et la page contient "Analyse de la déclaration"

  Scénario: Un agent peut demander une nouvelle vérification d'un site
    Sachant que je remplis "Adresse du site" avec "https://beta.gouv.fr"
    Et que je remplis "Nom du site" avec "beta.gouv.fr"
    Quand je clique sur "Ajouter"
    Et que je clique sur "Nouvelle vérification"
    Alors la page contient "Historique des vérifications (2)"

  Scénario: Un agent peut accéder aux étiquettes depuis la page du site
    Sachant que je possède un fichier "tmp/sites.csv" qui contient
      """
      url;tags
      https://beta.gouv.fr;éticouette
      """
    Et que j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Quand je clique sur "Importer"
    Et que je clique sur "Voir la fiche de beta.gouv.fr"
    Et que je clique sur "Étiquette éticouette"
    Alors la page est titrée "éticouette"

  Scénario: Un agent peut voir un lien sur chaque étiquette associée au site
    Sachant que je possède un site "https://example.gouv.fr"
    Et que le site "https://example.gouv.fr" a les étiquettes "production, public"
    Quand je clique sur "Tous les sites"
    Et que je clique sur "Voir la fiche de example.gouv.fr"
    Alors la page contient un lien vers "https://example.gouv.fr"
    Et la page contient un lien vers l'étiquette "production"
    Et la page contient un lien vers l'étiquette "public"

  Scénario: Un agent peut voir les informations et vérifications de l'audit
    Sachant que je possède un site "https://example.gouv.fr" avec des données
    Quand je clique sur "Tous les sites"
    Et que je clique sur "Voir la fiche de example.gouv.fr"
    Alors la page contient "Adresse du site"
    Et la page contient toutes les vérifications du site "https://example.gouv.fr"

  Scénario: Un agent peut voir l'historique des audits
    Sachant que je possède un site "https://example.gouv.fr"
    Et que je demande une nouvelle vérification du site "https://example.gouv.fr"
    Quand je clique sur "Tous les sites"
    Et que je clique sur "Voir la fiche de example.gouv.fr"
    Alors la page contient "Historique des vérifications"

  Scénario: Un agent voit un message quand le site n'a pas d'étiquettes
    Sachant que je possède un site "https://example.gouv.fr"
    Quand je clique sur "Tous les sites"
    Et que je clique sur "Voir la fiche de example.gouv.fr"
    Alors la page contient "Aucune étiquette"
