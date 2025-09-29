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
    Et la page contient "Informations sur l'audit"

  Scénario: Un agent peut demander une nouvelle vérification d'un site
    Sachant que je remplis "Adresse du site" avec "https://beta.gouv.fr"
    Et que je remplis "Nom du site" avec "beta.gouv.fr"
    Quand je clique sur "Ajouter"
    Et que je clique sur "Nouvelle vérification"
    Alors la page contient "Historique des vérifications (2)"
