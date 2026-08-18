# Changelog

## [2.0.0](https://github.com/betagouv/acces-cible/compare/v1.2.0...v2.0.0) (2026-08-18)


### ⚠ BREAKING CHANGES

* Add new attributes to checks and audits and backfill ([#672](https://github.com/betagouv/acces-cible/issues/672))

### Features

* Add a maximum session lifetime and shorten the idle timeout ([#674](https://github.com/betagouv/acces-cible/issues/674)) ([052830a](https://github.com/betagouv/acces-cible/commit/052830a8d980b8669c34255009d45e32433dfca8))
* add AuditBatch and rename batch processing services and jobs ([#679](https://github.com/betagouv/acces-cible/issues/679)) ([955852f](https://github.com/betagouv/acces-cible/commit/955852faa7a6290b1364c7e150268644cb1a3333))
* Add new attributes to checks and audits and backfill ([#672](https://github.com/betagouv/acces-cible/issues/672)) ([3aac1bc](https://github.com/betagouv/acces-cible/commit/3aac1bcc173a4a535d609823059fd4e64fac21e6))
* Change header and footer links ([#680](https://github.com/betagouv/acces-cible/issues/680)) ([8ad7a1b](https://github.com/betagouv/acces-cible/commit/8ad7a1bf17da9bd0da83961c3571a039efd7e562))
* Introduce `PageSnapshot` model and refactor page management ([#669](https://github.com/betagouv/acces-cible/issues/669)) ([b7eea5d](https://github.com/betagouv/acces-cible/commit/b7eea5dd3dd08314fff15bc7a44332ca971c68ad))


### Bug Fixes

* app not logging out from ProConnect ([#667](https://github.com/betagouv/acces-cible/issues/667)) ([e269e74](https://github.com/betagouv/acces-cible/commit/e269e74f48fa46f35ec653aa4181d8389fe0cbbe))
* Page snapshots backfill ([#675](https://github.com/betagouv/acces-cible/issues/675)) ([a5528e3](https://github.com/betagouv/acces-cible/commit/a5528e3cc51d10b89d64de855cb8a119ed9ee77b))


### Miscellaneous

* Move backfill of page snapshots to a one-off job ([#676](https://github.com/betagouv/acces-cible/issues/676)) ([ee8afbe](https://github.com/betagouv/acces-cible/commit/ee8afbed0ed74eaa1e76972339d28ec4ff12c2df))

## [1.2.0](https://github.com/betagouv/acces-cible/compare/v1.1.1...v1.2.0) (2026-07-30)


### Features

* Add `Privileged` concern to `Team` and `User` models ([#639](https://github.com/betagouv/acces-cible/issues/639)) ([5dfeb47](https://github.com/betagouv/acces-cible/commit/5dfeb476c96ac7fbd685eb637697e05ef00e3ab8))
* Add `rack-attack` for request throttling and abuse prevention ([#659](https://github.com/betagouv/acces-cible/issues/659)) ([b626910](https://github.com/betagouv/acces-cible/commit/b626910be2dc4255fafe204449026d17f9976ceb))
* Prevent site and tag editing from interface ([#643](https://github.com/betagouv/acces-cible/issues/643)) ([6ece5f0](https://github.com/betagouv/acces-cible/commit/6ece5f0b10223371af5c24a55ce7ec28d51eb877))
* Prevent site, audit and tag deletion from interface ([#637](https://github.com/betagouv/acces-cible/issues/637)) ([a5dd166](https://github.com/betagouv/acces-cible/commit/a5dd1667107f4542f9844ed8228849b39e80ab61))
* Remove `name` column from `sites` ([#641](https://github.com/betagouv/acces-cible/issues/641)) ([0b0bf74](https://github.com/betagouv/acces-cible/commit/0b0bf74b206bdb253746c873c27a73344273f9a7))
* Use ProConnect organization label for teams ([#668](https://github.com/betagouv/acces-cible/issues/668)) ([f54a52e](https://github.com/betagouv/acces-cible/commit/f54a52e7bbac7e3f93180e7b9ae0f5c2aa37b36a))


### Bug Fixes

* content type nil error ([#614](https://github.com/betagouv/acces-cible/issues/614)) ([f0586eb](https://github.com/betagouv/acces-cible/commit/f0586eb82717ae4a238aabe36c7b4377f38105c5))
* Link parsing, remove `LinkList` and refactor related code ([#636](https://github.com/betagouv/acces-cible/issues/636)) ([ab45952](https://github.com/betagouv/acces-cible/commit/ab45952e8d0ff8b097afe8398fba90a409193416))
* Network idling and timeout too long ([#627](https://github.com/betagouv/acces-cible/issues/627)) ([0074c45](https://github.com/betagouv/acces-cible/commit/0074c45d07e7db98032eda878af6531475ced11f))
* user name is now displayed on /user ([#646](https://github.com/betagouv/acces-cible/issues/646)) ([5d758c8](https://github.com/betagouv/acces-cible/commit/5d758c86060bc146e774317276593f646bafb26a))

## [1.1.1](https://github.com/betagouv/acces-cible/compare/v1.1.0...v1.1.1) (2026-07-08)


### Documentation

* Clean up README ([#625](https://github.com/betagouv/acces-cible/issues/625)) ([e688747](https://github.com/betagouv/acces-cible/commit/e6887479fb18dc4a5ecc6849ede721ecbba09934))

## [1.1.0](https://github.com/betagouv/acces-cible/compare/v1.0.0...v1.1.0) (2026-07-08)


### Features

* Add custom `User-Agent` header ([#601](https://github.com/betagouv/acces-cible/issues/601)) ([41ba748](https://github.com/betagouv/acces-cible/commit/41ba748a4ab2f1c77c1a1a3743785dfd0588b6eb))
* Enhance accessibility page detection ([#610](https://github.com/betagouv/acces-cible/issues/610)) ([cc7c88e](https://github.com/betagouv/acces-cible/commit/cc7c88e85fae1d671bfd261a4f129f3350b8585d))
* Link audits to users ([8af3c52](https://github.com/betagouv/acces-cible/commit/8af3c521254d0309c045f906a439aad44dbbb947))


### Bug Fixes

* Don't load HTML snapshots ([#593](https://github.com/betagouv/acces-cible/issues/593)) ([1ea5f80](https://github.com/betagouv/acces-cible/commit/1ea5f80be5f3397d50560947f389f279df4f5be1))
* Ensure user belongs to team in `ProcessBatchSitesCreationJob` ([31b25cc](https://github.com/betagouv/acces-cible/commit/31b25cc1a2bb02c963cd3321927a041018e31252))
* local test failure `run_axe_on_homepage_spec` ([#609](https://github.com/betagouv/acces-cible/issues/609)) ([7cb2215](https://github.com/betagouv/acces-cible/commit/7cb2215d4518ea3284a5721e39af86c3f3e3c893))
* Remove active record logs on Sentry ([#621](https://github.com/betagouv/acces-cible/issues/621)) ([2f9901e](https://github.com/betagouv/acces-cible/commit/2f9901e1110091cfcd2fdb3340c32516919feb3f))


### Documentation

* Update headings help page ([#602](https://github.com/betagouv/acces-cible/issues/602)) ([480a81c](https://github.com/betagouv/acces-cible/commit/480a81ccc838b87dc03e47945b2ac5750703a4f9))


### Miscellaneous

* add jemalloc buildpack ([#591](https://github.com/betagouv/acces-cible/issues/591)) ([3f55bab](https://github.com/betagouv/acces-cible/commit/3f55bab9854aee60d5ba46d2cf45a5fae55f83ef))
* Add missing audits controller request test ([81346d3](https://github.com/betagouv/acces-cible/commit/81346d3e24edfe40163cb0827c61bb58bd8fd76d))
* add obfuscated accessible email ([2024d66](https://github.com/betagouv/acces-cible/commit/2024d66e1e2ae1d39413ff90041759b54348a30a))
* Add release-please configuration and workflow ([#623](https://github.com/betagouv/acces-cible/issues/623)) ([9d392f2](https://github.com/betagouv/acces-cible/commit/9d392f2b2136fa32d79454956666538dec58971b))
* Bloquer plus d'extension de fichiers et de domaines de tracking ([#598](https://github.com/betagouv/acces-cible/issues/598)) ([8bbca89](https://github.com/betagouv/acces-cible/commit/8bbca8967a4ed7b897544fc0c97da887a6f3313c))
* Changer l'adresse mail de contact d'AC ([#618](https://github.com/betagouv/acces-cible/issues/618)) ([2024d66](https://github.com/betagouv/acces-cible/commit/2024d66e1e2ae1d39413ff90041759b54348a30a))
* isolate page in new_context that will be cleaned by ferrum ([#592](https://github.com/betagouv/acces-cible/issues/592)) ([9458967](https://github.com/betagouv/acces-cible/commit/9458967def9f10dfc095eaec72c49a178e050c47))
* Remove `current` column from `audits` table ([#580](https://github.com/betagouv/acces-cible/issues/580)) ([d225366](https://github.com/betagouv/acces-cible/commit/d225366c06bc03420ceb18dbe56c08e96dc3e559))
* Remove `url` column from `audits` table ([#582](https://github.com/betagouv/acces-cible/issues/582)) ([437de8a](https://github.com/betagouv/acces-cible/commit/437de8a76c7029a3d68af95fe5b686199bf983a4))
* Remove `url` from `audits` table ([437de8a](https://github.com/betagouv/acces-cible/commit/437de8a76c7029a3d68af95fe5b686199bf983a4))
* Remove inactive scopes and associated recurring jobs ([f953e8c](https://github.com/betagouv/acces-cible/commit/f953e8c17e7ddd0032a1d824a3ed7fae7ee913a8))
