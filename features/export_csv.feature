# language: fr

Fonctionnalité: Export d'un CSV
  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je rajoute un site "https://foobar.com/"
    Et que le site "https://foobar.com/" renvoie une réponse HTML normale pour la page d'accueil
    Et que le site "https://foobar.com/" renvoie une réponse HTML normale pour la déclaration d'accessibilité

  Scénario: je peux exporter le résultat en CSV
    Quand toutes les tâches de fond sont terminées
    Et que je choisis "Tous les sites" dans le menu principal
    Et que je clique sur "Télécharger en CSV"
    Alors la page contient un CSV dont une ligne commence par "foobar.com;https://foobar.com"
