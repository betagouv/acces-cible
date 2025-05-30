# Accès Cible

Application permettant de contrôler l'accessibilité des sites Internet, et les obligations légales liés à celle-ci.

## 🚀 Installation et démarrage

Pour démarrer le serveur, vous pouvez utiliser l'une des commandes suivantes :

```bash
docker compose up
```

ou, si ruby est installé sur votre poste (overmind est préconisé) :

```bash
bin/dev
```

## 🧰 Outils et technologies

- Framework : Ruby on Rails, ViewComponents, SolidQueue
- Tests : RSpec, Cucumber, Factory Bot
- UI : Composants DSFR (Design System de l'État Français)

## 📁 Organisation du code

- L'application est structurée en Modèle/View/Controller (MVC) avec une architecture REST, comme Rails le préconise.
- Plusieurs classes ne sont pas liées à des tables (PORO). Par exemple :
  - `Browser`, une surcouche pour Ferrum, qui pilote Chrome.
  - `Crawler`, `Page`, `Link`,  `LinkList`, `AxeViolation`, `PageHeadingStatus`, ou encore `SiteUpload`.
  Parmi ces classes, celles dont les données n'ont pas vocation à être modifiées s'appuient sur le générateur [Data](https://docs.ruby-lang.org/en/3.2/Data.html).
- Les utilisateurs manipulent des sites, qui sont ensuite vérifiés (modèle Audit) selon plusieurs points de contrôle (modèle Check). Les différents points de contrôles héritent de `Check`, ils sont placés dans le dossier `checks`. Les différents points de contrôle sont triés par priorité afin de gérer les dépendances entre les uns et les autres.
- L'adresse des sites est stockée au niveau de l'audit, afin d'autoriser les sites à changer d'adresse (que ce soit en passant au `https`, par l'ajout d'un sous-domaine `www`, ou autre). Lors de la création d'un site, l'adresse saisie est donc comparée avec les adresses disponibles afin d'éviter des doublons.
- Helpers : le module `ApplicationHelper` contient un certain nombre de fonctions permettant de simplifier la génération de liens avec icône, de composants DSFR internes au projet, etc.
- Le titre des pages est obligatoire, il est généré automatiquement par la méthode `page_title`, soit en étant défini directement (`@title`), soit via `content_for(:title)`, soit en appelant `to_title` sur la ressource affichée, soit via I18n (`[contrôleur].[action].title`).
- Les composants du DSFR, s'ils ne sont pas encore implémentés dans [DSFR view components](https://github.com/betagouv/dsfr-view-components/), sont définis dans `app/components/dsfr/`. Une fois créés et stabilisés suite à leur usage dans le projet, les remonter dans la gemme pour que tout le monde en profite.
- Pour simplifier la génération des textes, `human_attribute_name` est raccourci en `human` et rendu disponible dans toutes les classes héritant d'`ApplicationRecord`. Un helper `to_percentage` est également proposé afin d'harmoniser l'affichage de ce type de chiffres.

## 📝 Conventions de codage

- Le style Ruby suit les conventions Rails Omakase (style officiel de Rails)
- Utiliser des guillemets doubles pour les chaînes de caractères (`"exemple"`)
- Utiliser des symboles plutôt que des chaînes quand les deux sont possibles

## 🤝 Contribution

- La branche principale (`main`) est déployée en production
- La branche de préproduction (`staging`) est déployée en staging
- Les commits poussés sur la branche principale utilisent [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#summary)
  Exemples de préfixes : `fix:`, `feat:`, `chore:`, `ci:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, etc.

## 🧪 Tests

### Exécuter tous les tests
```bash
bundle exec rspec
```

### Exécuter un test spécifique
```bash
bundle exec rspec spec/path/to/file_spec.rb:NUMÉRO_DE_LIGNE
```

### Exécuter des tests de fonctionnalités
```bash
bundle exec cucumber features/fonctionnalité_spécifique.feature
```

## 🧹 Linting

### Vérifier le code
```bash
make lint
```
ou
```bash
bundle exec rubocop
```

### Correction automatique des problèmes de style
```bash
bundle exec rubocop -a
```
