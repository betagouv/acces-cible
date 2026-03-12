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
    Alors la section "Analyse de la déclaration" indique "<résultat>"

    Exemples:
      | contenu                                                                      | résultat                                 |
      | <h2>Retour d'information et contact</h2><p>emily@xie.com</p><h2>Autre</h2>   | Adresse email de contact : emily@xie.com |
      | <h2>Retour d'information et contact</h2><p>pas d'email ici</p><h2>Autre</h2> | Adresse email de contact : Non détecté   |

  Plan du scénario: extrait le formulaire de contact avec priorité
    Sachant que le site "https://foobar.com/" renvoie "<contenu>" pour la déclaration d'accessibilité
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Alors la section "Analyse de la déclaration" indique "<résultat>"

    Exemples:
      | contenu                                                                                                            | résultat                                            |
      | <h2>Retour d'information et contact</h2><p><a href='/42'>Formulaire de contact</a></p><h2>Autre</h2>               | Formulaire de contact : https://foobar.com/42       |
      | <h2>Retour d'information et contact</h2><p><a href='https://foobear.com/contact'>Nous écrire</a></p><h2>Autre</h2> | Formulaire de contact : https://foobear.com/contact |
      | <h2>Retour d'information et contact</h2><p><a href='https://something.com/'>Nous écrire</a></p><h2>Autre</h2>      | Formulaire de contact : Non détecté                 |
