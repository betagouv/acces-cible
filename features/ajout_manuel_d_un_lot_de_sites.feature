# language: fr

Fonctionnalité: Ajout manuel d'un lot de sites

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je choisis "Mes évaluations" dans le menu principal
    Et que je clique sur "Lancer une évaluation"
    Et que je choisis "Saisir des adresses"
    Et que je clique sur "Continuer"

  Scénario: L'adresse du site est obligatoire
    Quand je clique sur "Continuer"
    Alors la page contient "Saisissez au moins une adresse."

  Scénario: Un agent peut ajouter un site manuellement
    Sachant que je remplis "Adresse du site" avec "beta.gouv.fr"
    Quand je clique sur "Continuer"
    Alors la page contient "Adresse du site n'est pas valide"
    Quand je remplis "Adresse du site" avec "https://beta.gouv.fr/"
    Et que je clique sur "Continuer"
    Et que je clique sur "Continuer"
    Et que je clique sur "Lancer l'évaluation"
    Alors la page contient "Évaluations lancées"

  Scénario: Un agent suit l'avancement de ses évaluations
    Sachant que le site "https://beta.gouv.fr/" renvoie une réponse HTML normale pour la page d'accueil
    Et que le site "https://beta.gouv.fr/" renvoie une réponse HTML normale pour la déclaration d'accessibilité
    Et que je remplis "Adresse du site" avec "https://beta.gouv.fr/"
    Et que je clique sur "Continuer"
    Et que je clique sur "Continuer"
    Quand je clique sur "Lancer l'évaluation"
    Alors la page contient "Création des évaluations en cours"
    Quand le lancement est terminé
    Et que je recharge la page
    Alors la page contient "En cours"
    Et la page contient un lien "beta.gouv.fr"
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Alors la page contient "Terminée"
    Et la page contient "Toutes les évaluations sont terminées"
    Quand je clique sur "beta.gouv.fr"
    Alors le titre de la page contient "beta.gouv.fr"

  Scénario: Un agent peut saisir une adresse puis la corriger
    Sachant que je remplis "Adresse du site" avec "https://beta.gouv.fr/"
    Et que je clique sur "Continuer"

    Quand je clique sur "Retour"
    Alors le champ "Adresse du site" contient "https://beta.gouv.fr/"

    Quand je remplis "Adresse du site" avec "https://numerique.gouv.fr/"
    Et que je clique sur "Continuer"
    Alors la page contient "numerique.gouv.fr"
    Et la page ne contient pas "beta.gouv.fr"

  Scénario: Un agent peut étiqueter un site
    Sachant que je remplis "Adresse du site" avec "https://beta.gouv.fr/"
    Et que je clique sur "Continuer"
    Quand je crée l'étiquette "ministère" pour le site "beta.gouv.fr"
    Alors l'étiquette "ministère" est sélectionnée pour le site "beta.gouv.fr"
    Quand je clique sur "Continuer"
    Et que je clique sur "Lancer l'évaluation"
    Et que le lancement est terminé
    Et que je choisis "Mes évaluations" dans le menu principal
    Et que je clique sur "beta.gouv.fr"
    Alors la page contient "ministère"
