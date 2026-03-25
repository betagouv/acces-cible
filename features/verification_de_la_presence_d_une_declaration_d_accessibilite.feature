# language: fr

Fonctionnalité: Vérifications de la présence d'une déclaration d'accessibilité

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je rajoute un site "https://foobar.com/"

  Plan du scénario: indique la présence d'une déclaration d'accessibilité
    Sachant que le site "https://foobar.com/" renvoie "<contenu>" pour la page d'accueil
    Sachant que l'adresse "<url>" renvoie une réponse HTML normale pour la déclaration d'accessibilité
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Alors la vérification "Présence d'une déclaration d'accessibilité" indique "Déclaration d'accessibilité"
    Et la section "Présence d'une déclaration d'accessibilité" indique "<résultat>"

    Exemples:
      | contenu                                                                              | url                                        | résultat                                           |
      | <a href='https://external.example.org/accessibilite'>Déclaration d'accessibilité</a> | https://external.example.org/accessibilite | Cette déclaration est hébergée hors du site audité |
      | <a href='https://foobar.com/accessibilite'>Déclaration d'accessibilité</a>           | https://foobar.com/accessibilite           | Déclaration d'accessibilité                        |

  Scénario: aucune déclaration ne déclenche pas de message supplémentaire
    Sachant que le site "https://foobar.com/" renvoie "<p>Bienvenue</p>" pour la page d'accueil
    Et que toutes les tâches de fond sont terminées
    Et que je recharge la page
    Alors la vérification "Présence d'une déclaration d'accessibilité" indique "Non trouvé"
    Et la section "Présence d'une déclaration d'accessibilité" n'indique pas "Cette déclaration est hébergée hors du site audité"
