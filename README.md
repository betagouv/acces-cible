# Accès Cible

Application permettant de contrôler l'accessibilité des sites Internet, et les obligations légales liés à celle-ci.

Production : https://acces-cible.beta.gouv.fr/

Staging : https://acces-cible.incubateur.net/

## 🚀 Installation et démarrage

- Demandez la `master.key` aux membres de votre équipe
- Placez-la dans `config/`

Pour démarrer le serveur, vous pouvez utiliser l'une des commandes suivantes :

Docker:

```bash
make build # docker compose build
make up # docker compose up
make die # docker compose down

make cl # rails c
make sh # bash
```

### Jobs & Mission control job

Afin d'accéder à l'interface utilisateur des jobs, vous devrez vous connecter sur [mission control jobs](https://github.com/rails/mission_control-jobs) en local.

- Récupérer les informations de connexion à partir des credentials :
    - Lancer un bash avec `make sh`
    - Exécuter `rails credentials:show`
- Allez sur `http://localhost:3000/jobs`
- Renseignez ces informations dans le formulaire de connexion

### Connexion en local

- Dirigez-vous sur `http://localhost:3000`
- Cliquez sur `Se connecter en mode développeur`
- Renseignez des informations factices dans le formulaire

### Connexion au serveur

Pour faciliter la connexion aux serveurs, utiliser le script `bin/scalingo`.

Par défaut, il se connecte au staging, mais on peut préciser `prod` pour accéder à la production.
L'option `-s` ou `--sandbox`  permet d'activer le mode [sandbox](https://guides.rubyonrails.org/command_line.html#bin-rails-console).

```bash
# Staging
bin/scalingo
bin/scalingo -s

# Production
bin/scalingo prod
bin/scalingo prod --sandbox
```

## 🧰 Outils et technologies

- Framework : Ruby on Rails, ViewComponents, SolidQueue
- Tests : RSpec, Cucumber, Factory Bot
- UI : Composants DSFR (Design System de l'État Français)

### Mise à jour des dépendances

Les tests automatique d'accessibilité utilisent Axe-core, localisé en français.
Le navigateur utilise puppeteer-stealth-evasion pour éviter d'être identifié comme un robot.
Pour mettre à jour ces dépendances, il suffit de lancer la commande suivante :

```shell
bin/rails vendor:update
```

## 📁 Organisation du code

- L'application est structurée en Modèle/View/Controller (MVC) avec une architecture REST, comme Rails le préconise.
- Plusieurs classes ne sont pas liées à des tables (PORO). Par exemple :
    - `Browser`, une surcouche pour Ferrum, qui pilote Chrome.
    - `Crawler`, `Page`, `Link`,  `LinkList`, `AxeViolation`, `PageHeadingStatus`, ou encore `SiteUpload`.
      Parmi ces classes, celles dont les données n'ont pas vocation à être modifiées s'appuient sur le
      générateur [Data](https://docs.ruby-lang.org/en/3.2/Data.html).
- Les utilisateurs manipulent des sites, qui sont ensuite vérifiés (modèle Audit) selon plusieurs points de contrôle (
  modèle Check). Les différents points de contrôles héritent de `Check`, ils sont placés dans le dossier `checks`. Les
  différents points de contrôle sont triés par priorité afin de gérer les dépendances entre les uns et les autres.
- L'adresse des sites est stockée au niveau de l'audit, afin d'autoriser les sites à changer d'adresse (que ce soit en
  passant au `https`, par l'ajout d'un sous-domaine `www`, ou autre). Lors de la création d'un site, l'adresse saisie
  est donc comparée avec les adresses disponibles afin d'éviter des doublons.
- Helpers : le module `ApplicationHelper` contient un certain nombre de fonctions permettant de simplifier la génération
  de liens avec icône, de composants DSFR internes au projet, etc.
- Le titre des pages est obligatoire, il est généré automatiquement par la méthode `page_title`, soit en étant défini
  directement (`@title`), soit via `content_for(:title)`, soit en appelant `to_title` sur la ressource affichée, soit
  via I18n (`[contrôleur].[action].title`).
- Les composants du DSFR, s'ils ne sont pas encore implémentés
  dans [DSFR view components](https://github.com/betagouv/dsfr-view-components/), sont définis dans
  `app/components/dsfr/`. Une fois créés et stabilisés suite à leur usage dans le projet, les remonter dans la gemme
  pour que tout le monde en profite.

## 📝 Conventions de codage

- Le style Ruby suit les conventions Rails Omakase (style officiel de Rails)
- Utiliser des guillemets doubles pour les chaînes de caractères (`"exemple"`)
- Utiliser des symboles plutôt que des chaînes quand les deux sont possibles

## 🤝 Contribution

- La branche principale est `main`, elle est déployée en `staging` à chaque push.
- Pas de push direct sur `production`.
- Les messages de commit suivent la convention [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#summary) (`fix:`, `feat:`, `chore:`, etc.).

### Releases et déploiement en production

Les releases sont gérées automatiquement par [release-please](https://github.com/googleapis/release-please) :

1. Chaque push sur `main` met à jour (ou crée) une PR de release avec le changelog et le bump de version.
2. Merger cette PR crée un tag GitHub et fast-forward merge `main` sur `production`, ce qui déclenche le déploiement en production.

## Particularités

### Helpers et raccourcis

Pour améliorer l'expérience développeur, des raccourcis et des outils ont été mis en place

- `bulk_reset_counter(association, counter: nil)` fait ce qu'on attend de `reset_counters` : prendre un nom d'association, le nom du compteur s'il diffère du nom par défaut, et met à jour toute la table en une seule requête SQL. TODO : proposer de l'upstreamer dans Rails.
- `page_title` : récupère ou génère le titre de page. Cherche successivement dans `@title`, `content_for(:title)`, la méthode `to_title` de la ressource courante si on est dans une action de type `:show`, ou dans la configuration I18n du contrôleur courant.
- `head_title` : concatène le titre de page et le nom du site, et l'insère dans le layout principal.
- `page_actions` permet de regrouper les boutons et actions, avec les mêmes styles d'une page à l'autre.

### Extensions ActiveRecord

- `to_csv` et `to_csv_filename` sont injectées dans `ActiveRecord`, pour permettre d'exporter une requête en CSV avec un minimum de configuration.

### Composants

Les composants DSFR qui ne sont pas encore implémentés dans dsfr-view-components sont implémentés dans le dossier
`app/components/dsfr/`. Des helpers sont également inclus pour les appeler avec une syntaxe concise et des valeurs par défaut logiques.

## 🧪 Tests

### Docker setup

```shell
make sh # bash
./bin/rails db:setup RAILS_ENV=test
```

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

## 🔬 Outils de debugging

### Debugger

Dans l'environnement Docker, vous pouvez utiliser `debug` pour
arrêter et explorer votre code à un endroit précis :

1. rajoutez un breakpoint avec l'appel `debugger` :

```diff
def some_method
+  debugger
  a = "foobar"
end
```

2. une fois le code arrêté :

```
web-1          | DEBUGGER: wait for debugger connection...
```

ouvrez un terminal et lancez `make debug` qui se connecte
automatiquement au debugger.

### Prévisualiser une page crawlée

Le script `bin/preview_audit` permet d'ouvrir le HTML crawlé d'un audit dans le navigateur.

```bash
bin/preview_audit home|accessibility [AUDIT_ID]
```

- `home` : page d'accueil crawlée
- `accessibility` : page accessibilité crawlée
- `AUDIT_ID` : optionnel, utilise le dernier audit si absent

Exemples :

```bash
bin/preview_audit home 42
bin/preview_audit accessibility
```

Le fichier généré est placé dans `tmp/` et le chemin est affiché en sortie.
