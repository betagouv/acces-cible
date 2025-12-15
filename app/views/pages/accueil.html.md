<% use_centered_layout(boxed: false) %>

**Accès cible permet de contrôler la conformité légale des sites Internet par rapport à l'accessibilité.**

## Contrôles effectués

L'outil effectue différents contrôles sur les sites qui lui sont indiqués:

- présence d'une mention « Accessibilité : totalement conforme/partiellement conforme/non conforme » ;
- une page d'accessibilité conforme avec le modèle officiel ;
- un schéma pluriannuel d'amélioration de l'accessibilité, un plan d'actions et un bilan annuel ;
- ainsi que d'autres contrôles complémentaires.

## Ajout de sites

Les sites peuvent être ajoutés soit un par un, en indiquant l'adresse, ainsi éventuellement qu'un nom et des étiquettes, ou en envoyant une liste de sites au format <abbr>CSV</abbr>.

## Présentation des résultats

Les résultats d'analyse d'un site sont présentés de manière à faciliter la correction des problèmes rencontrés.

Un tableau donne une vision synthétique des différents sites ajoutés, pour faciliter la comparaison.

## À qui s'adresse ce service ?

**Arcom**

L’[ordonnance de transposition du 6 septembre 2023](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000048049674) a défini de nouvelles missions de l’Arcom en créant l’[article 47-1 de la loi n°2005-102](https://www.legifrance.gouv.fr/loda/article_lc/LEGIARTI000048050174) qui précise :
Afin de faciliter le contrôle de ces obligations, elle peut mettre en œuvre des méthodes proportionnées de **collecte automatisée** de données publiquement accessibles.
Cette plateforme vise à doter l'Arcom d’un service automatisé de contrôle afin de remplir cette mission.

**Administrations**

Les collectivités territoriales, l’État, ses services déconcentrés et ses opérateurs doivent respecter le RGAA, mais n'ont pas toujours les moyens de s'autocontrôler afin d’améliorer l’accessibilité de leurs services numériques.

**Délégataires de service public**

Les organisations délégataires d’une mission de service public ou sous contrôle d’une administration doivent produire des sites et applications accessibles, au même titre que l'administration qui les missionne.

**Entreprises**

Les entreprises dont le chiffre d’affaires en France est supérieur à 250 millions d’euros doivent également respecter le <abbr>RGAA</abbr>.

La connexion utilisateur s'effectue grâce à [ProConnect](https://www.proconnect.gouv.fr/), qui peut être utilisé par tous les professionnels du public comme du privé.
Vérifiez votre éligibilité en cliquant sur le bouton **S'identifier avec ProConnect**.
Les personnes de votre équipe (selon les informations fournies par ProConnect) ont accès aux sites et aux résultats des contrôles effectués.

## Statistiques

<div class="fr-grid-row fr-grid-row--gutters fr-mb-2v">
  <div class="fr-col-12 fr-col-sm">
    <div class="fr-card fr-p-2w">
      <h3 class="fr-mb-5w text-center blue-title">Sites contrôlés</h3>
      <p class="fr-mb-2w">
        <%= Site.human_count %>
      </p>
    </div>
  </div>
  <div class="fr-col-12 fr-col-sm">
    <div class="fr-card fr-p-2w">
      <h3 class="fr-mb-5w text-center blue-title">Équipes utilisatrices</h3>
      <p class="fr-mb-2w">
        <%= Team.human_count %>
      </p>
    </div>
  </div>
</div>
