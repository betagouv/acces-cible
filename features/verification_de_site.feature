# language: fr

Fonctionnalité: Vérifications d'un site
  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je rajoute un site "http://foobar.com/" qui renvoie une réponse HTML normale

  Scénario: je peux voir que les vérifications vont être lancées
    Alors la page contient "État : Planifié"

  Scénario: je peux voir quand l'audit est fini
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Alors la page contient "Executé le : "
    Et la vérification "Site joignable" indique "Joignable à l'adresse indiquée"
