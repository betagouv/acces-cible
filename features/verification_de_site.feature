# language: fr

Fonctionnalité: Vérifications d'un site

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je rajoute un site "https://foobar.com/"
    Et que le site "https://foobar.com/" renvoie une réponse HTML normale pour la page d'accueil
    Et que le site "https://foobar.com/" renvoie une réponse HTML normale pour la déclaration d'accessibilité

  Scénario: je peux voir que les vérifications vont être lancées
    Alors la page contient "Évaluation en cours"

  Scénario: je peux voir le résultat de chaque vérification
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Et que je clique sur "Voir le résultat"
    Alors le résumé "Niveau d'accessibilité déclaré" indique "Non trouvée"
    Et le résumé "Respect des obligations légales" indique "1 obligation sur 4 remplie"
    Et le résumé "Qualité de la déclaration" indique "8 éléments à corriger sur 8"
    Et la vérification "Présence d'une déclaration d'accessibilité" de la carte "Obligations légales" indique "Déclaration d'accessibilité"
    Et la vérification "Titres de la déclaration d'accessibilité" de la carte "Qualité de la déclaration" indique "Invalide"
    Et la vérification "Schéma pluriannuel d'accessibilité" de la carte "Qualité de la déclaration" indique "Absent"
    Et la vérification "Plan d'action" de la carte "Qualité de la déclaration" indique "Absent"

  Plan du scénario: la mention du niveau d'accessibilité est détectée sur la page d'accueil
    Sachant que le site "https://foobar.com/" renvoie "<contenu>" pour la page d'accueil
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Et que je clique sur "Voir le résultat"
    Alors le résumé "Niveau d'accessibilité déclaré" indique "<résultat>"

    Exemples:
      | contenu                                                | résultat               |
      | <p>Accessibilité : totalement conforme au RGAA.</p>    | Totalement conforme    |
      | <p>Accessibilité : partiellement conforme au RGAA.</p> | Partiellement conforme |
      | <p>Accessibilité : non conforme au RGAA.</p>           | Non conforme           |
      | <p>C'est hyper</p>                                     | Non trouvée            |

  Scénario: les vérifications de la page d'accessibilité ne sont pas lancées sans contenu
    Quand le site "https://foobar.com/" ne trouve pas de page d'accessibilité
    Et que toutes les tâches de fond sont terminées
    Et que je recharge la page
    Et que je clique sur "Voir le résultat"
    Alors la page contient "Déclaration d'accessibilité non trouvée"
    Et la vérification "Présence d'une déclaration d'accessibilité" de la carte "Obligations déclaratives" indique "Absent"
    Et la vérification "Mention du niveau d'accessibilité" de la carte "Obligations déclaratives" indique "Absent"
