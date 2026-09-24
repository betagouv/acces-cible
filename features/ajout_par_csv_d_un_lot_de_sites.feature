# language: fr

Fonctionnalité: Ajout par CSV d'un lot de sites

  Contexte:
    Sachant que je suis "marie.curie@gouv.fr" avec le SIRET 123 de l'organisation "DINUM"
    Et que je me pro-connecte
    Et que je choisis "Mes évaluations" dans le menu principal
    Et que je clique sur "Lancer une évaluation"
    Et que je choisis "Importer un CSV"
    Et que je clique sur "Continuer"

  Scénario: Le fichier CSV est obligatoire
    Quand je clique sur "Continuer"
    Alors la page contient "Fichier CSV doit contenir au moins une adresse."

  Scénario: Un agent peut importer un CSV de sites avec leurs étiquettes
    Sachant que je possède un fichier "tmp/sites.csv" qui contient
      """
      url;tags
      https://beta.gouv.fr;beta
      https://numerique.gouv.fr;gouv,public
      """
    Quand j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Et que je clique sur "Continuer"
    Alors l'étiquette "beta" est sélectionnée pour le site "beta.gouv.fr"
    Et l'étiquette "public" est sélectionnée pour le site "numerique.gouv.fr"
    Quand je clique sur "Continuer"
    Et que je clique sur "Lancer l'évaluation"
    Alors la page contient "Évaluations lancées"

  Scénario: Un agent peut étiqueter un site importé
    Sachant que je possède un fichier "tmp/sites.csv" qui contient
      """
      url
      https://beta.gouv.fr
      """
    Quand j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Et que je clique sur "Continuer"
    Et que je crée l'étiquette "ministère" pour le site "beta.gouv.fr"
    Et que je clique sur "Continuer"
    Et que je clique sur "Lancer l'évaluation"
    Et que le lancement est terminé
    Et que je choisis "Mes évaluations" dans le menu principal
    Et que je clique sur "beta.gouv.fr"
    Alors la page contient "ministère"

  Scénario: La liste des sites importés est paginée
    Sachant que je possède un fichier "tmp/sites.csv" qui contient
      """
      url;tags
      https://site-01.example.com;
      https://site-02.example.com;
      https://site-03.example.com;
      https://site-04.example.com;
      https://site-05.example.com;
      https://site-06.example.com;
      https://site-07.example.com;
      https://site-08.example.com;
      https://site-09.example.com;
      https://site-10.example.com;
      https://site-11.example.com;dernier
      """
    Quand j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Et que je clique sur "Continuer"
    Alors la page contient "site-01.example.com"
    Et la page ne contient pas "site-11.example.com"
    Quand je crée l'étiquette "premier" pour le site "site-01.example.com"
    Et que je clique sur "Page suivante"
    Alors la page contient "site-11.example.com"
    Et la page ne contient pas "site-01.example.com"
    Et l'étiquette "dernier" est sélectionnée pour le site "site-11.example.com"
    Quand je clique sur "Page précédente"
    Alors la page contient "site-01.example.com"
    Et l'étiquette "premier" est sélectionnée pour le site "site-01.example.com"

  Scénario: La liste des évaluations lancées est paginée
    Sachant que je possède un fichier "tmp/sites.csv" qui contient
      """
      url
      https://site-01.example.com
      https://site-02.example.com
      https://site-03.example.com
      https://site-04.example.com
      https://site-05.example.com
      https://site-06.example.com
      https://site-07.example.com
      https://site-08.example.com
      https://site-09.example.com
      https://site-10.example.com
      https://site-11.example.com
      """
    Quand j'attache le fichier "tmp/sites.csv" pour le champ "Fichier CSV"
    Et que je clique sur "Continuer"
    Et que je clique sur "Continuer"
    Et que je clique sur "Lancer l'évaluation"
    Et que le lancement est terminé
    Et que je recharge la page
    Alors la page contient "site-01.example.com"
    Et la page ne contient pas "site-11.example.com"
    Quand je clique sur "2"
    Alors la page contient "site-11.example.com"
    Et la page ne contient pas "site-01.example.com"
