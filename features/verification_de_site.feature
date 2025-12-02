# language: fr

Fonctionnalité: Vérifications d'un site
  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je rajoute un site "https://foobar.com/"
    Et que le site "https://foobar.com/" renvoie une réponse HTML normale pour la page d'accueil
    Et que le site "https://foobar.com/" renvoie une réponse HTML normale pour la déclaration d'accessibilité

  Scénario: je peux voir que les vérifications vont être lancées
    Alors la page contient "État : Planifié"

  Scénario: je peux voir le résultat de chaque vérification
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Alors la vérification "Site joignable" indique "Joignable à l'adresse indiquée"
    Et la vérification "Indication de la langue" indique "Absente"
    Et la vérification "Mention du niveau d'accessibilité" indique "Absente"
    Et la vérification "Présence d'une déclaration d'accessibilité" indique "Non trouvée"
    Et la vérification "Analyse de la déclaration" indique "Échoué"
    Et la vérification "Titres de la déclaration d'accessibilité" indique "Échoué"
    Et la vérification "Schéma pluriannuel d'accessibilité" indique "Échoué"
    Et la vérification "Plan d'action" indique "Échoué"
    Et la vérification "Contrôles automatiques : page d'accueil" indique "50%"
