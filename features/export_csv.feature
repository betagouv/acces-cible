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
    Alors la page retourne un CSV dont une ligne commence par "foobar.com;Site title;https://foobar.com"

  Scénario: je peux exporter uniquement un site sélectionné
    Sachant que je rajoute un site "https://example.com/"
    Et que je choisis "Tous les sites" dans le menu principal
    Quand je coche "Sélectionner foobar.com"
    Et que je clique sur "Télécharger en CSV"
    Alors la page retourne un CSV qui contient strictement les sites "foobar.com"

  Scénario: je peux exporter uniquement le site sélectionné après filtre et tri
    Sachant que je possède un fichier "tmp/sites.csv" qui contient
      """
      url;tags
      https://beta.gouv.fr;beta
      https://numerique.gouv.fr;gouv,public
      https://www.suresnes.fr;public
      """
    Et que je choisis "Ajouter un site" dans le menu principal
    Et que j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Quand je clique sur "Importer"
    Et que je clique sur "Trier par Adresse du site croissant"
    Et que je filtre par étiquette "public"
    Et que je clique sur "Télécharger en CSV"
    Alors la page retourne un CSV qui contient strictement les sites "numerique.gouv.fr, suresnes.fr"
