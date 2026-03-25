# language: fr

Fonctionnalité: Vérifications de la présence d'une déclaration d'accessibilité

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je rajoute un site "https://foobar.com/"
    Et que le site "https://foobar.com/" renvoie une réponse HTML normale pour la page d'accueil

  Scénario: la déclaration externe est signalée dans la section
    Sachant que le site "https://foobar.com/" renvoie "<h1>Déclaration d'accessibilité</h1>" à l'adresse "https://external.example.org/accessibilite" pour la déclaration d'accessibilité
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Alors la vérification "Présence d'une déclaration d'accessibilité" indique "Déclaration d'accessibilité"
    Et la section "Présence d'une déclaration d'accessibilité" indique "Cette déclaration est hébergée hors du site audité"

  Scénario: la déclaration interne ne déclenche pas de message supplémentaire
    Sachant que le site "https://foobar.com/" renvoie "<h1>Déclaration d'accessibilité</h1>" pour la déclaration d'accessibilité
    Quand toutes les tâches de fond sont terminées
    Et que je recharge la page
    Alors la vérification "Présence d'une déclaration d'accessibilité" indique "Déclaration d'accessibilité"
    Et la section "Présence d'une déclaration d'accessibilité" n'indique pas "Cette déclaration est hébergée hors du site audité"

  Scénario: aucune déclaration ne déclenche pas de message supplémentaire
    Quand le site "https://foobar.com/" ne trouve pas de page d'accessibilité
    Et que toutes les tâches de fond sont terminées
    Et que je recharge la page
    Alors la vérification "Présence d'une déclaration d'accessibilité" indique "Non trouvé"
    Et la section "Présence d'une déclaration d'accessibilité" n'indique pas "Cette déclaration est hébergée hors du site audité"
