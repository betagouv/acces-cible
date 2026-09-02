# language: fr

Fonctionnalité: Vérifications de l'analyse de la page d'accessibilité

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je rajoute un site "https://foobar.com/"
    Et que le site "https://foobar.com/" renvoie une réponse HTML normale pour la page d'accueil

  Plan du scénario: extrait l'email de contact
    Sachant que le site "https://foobar.com/" renvoie "<contenu>" pour la déclaration d'accessibilité
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Et que je clique sur "Voir le résultat"
    Alors la vérification "Adresse email ou formulaire de contact" de la carte "Qualité de la déclaration" indique "<résultat>"

    Exemples:
      | contenu                                                                      | résultat      |
      | <h2>Retour d'information et contact</h2><p>emily@xie.com</p><h2>Autre</h2>   | emily@xie.com |
      | <h2>Retour d'information et contact</h2><p>pas d'email ici</p><h2>Autre</h2> | -             |

  Plan du scénario: extrait le formulaire de contact avec priorité
    Sachant que le site "https://foobar.com/" renvoie "<contenu>" pour la déclaration d'accessibilité
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Et que je clique sur "Voir le résultat"
    Alors la vérification "Adresse email ou formulaire de contact" de la carte "Qualité de la déclaration" contient un lien vers "<url>"

    Exemples:
      | contenu                                                                                              | url                   |
      | <h2>Retour d'information et contact</h2><p><a href='/42'>Formulaire de contact</a></p><h2>Autre</h2> | https://foobar.com/42 |


  Plan du scénario: extrait le référentiel utilisé pour l'audit
    Sachant que le site "https://foobar.com/" renvoie "<contenu>" pour la déclaration d'accessibilité
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Et que je clique sur "Voir le résultat"
    Alors la vérification "Référentiel" de la carte "Qualité de la déclaration" indique "<résultat>"

    Exemples:
      | contenu                               | résultat  |
      | <p>Ce site respecte le RGAA v4.1.</p> | RGAA v4.1 |
      | <p>C'est hyper</p>                    | -         |

  Plan du scénario: extrait l'auditeur ayant réalisé l'audit
    Sachant que le site "https://foobar.com/" renvoie "<contenu>" pour la déclaration d'accessibilité
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Et que je clique sur "Voir le résultat"
    Alors la vérification "Audit réalisé par" de la carte "Qualité de la déclaration" indique "<résultat>"

    Exemples:
      | contenu                                                                            | résultat       |
      | <h2>Résultats des tests</h2><p>Audit réalisé par Mitchell Baker.</p><h2>Autre</h2> | Mitchell Baker |
      | <h2>Résultats des tests</h2><p>C'est hyper</p><h2>Autre</h2>                       | -              |

  Plan du scénario: extrait la date de la déclaration
    Sachant que le site "https://foobar.com/" renvoie "<contenu>" pour la déclaration d'accessibilité
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Et que je clique sur "Voir le résultat"
    Alors la vérification "Date de la déclaration" de la carte "Qualité de la déclaration" indique "<résultat>"

    Exemples:
      | contenu                                                                                                | résultat |
      | <h1>Déclaration</h1><p>Cette déclaration a été établie le 11 mars 2025.</p><h2>État de conformité</h2> | Présent  |
      | <h1>Déclaration</h1><p>C'est hyper</p><h2>État de conformité</h2>                                      | Absent   |

  Plan du scénario: détecte la mention de l'article de loi
    Sachant que le site "https://foobar.com/" renvoie "<contenu>" pour la déclaration d'accessibilité
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Et que je clique sur "Voir le résultat"
    Alors la vérification "Mentionne l'article de loi" de la carte "Qualité de la déclaration" indique "<résultat>"

    Exemples:
      | contenu                                                                      | résultat |
      | <p>Conformément à l'article 47 de la loi n° 2005-102 du 11 février 2005.</p> | Oui      |
      | <p>C'est hyper</p>                                                           | Non      |
