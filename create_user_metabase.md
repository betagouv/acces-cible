# Creer un utilisateur Metabase avec accès restreint aux audits et sites

Cet utilisateur doit :

- voir toutes les tables ordinaires de `public` ;
- ne pas pouvoir lire directement `public.audits` ni `public.sites` ;
- pouvoir lire les versions caviardées `metabase.audits` et `metabase.sites`.

Le chemin est donc :

```text
Metabase
   ↓ connexion avec metabase_reader
Tables public ordinaires
+ metabase.audits
+ metabase.sites
```

Et surtout pas :

```text
Metabase → utilisateur admin → public.audits/public.sites
```

La migration crée uniquement les vues. La création du compte et les permissions se font séparément sur PostgreSQL, par exemple :

```sql
CREATE ROLE metabase_reader
  LOGIN
  PASSWORD '******';

GRANT CONNECT ON DATABASE acces_cible_production TO metabase_reader;

GRANT USAGE ON SCHEMA public, metabase TO metabase_reader;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO metabase_reader;

REVOKE SELECT ON public.audits, public.sites
FROM metabase_reader;

GRANT SELECT ON metabase.audits, metabase.sites
TO metabase_reader;

ALTER ROLE metabase_reader
SET search_path TO metabase, public;
```

Pour rendre automatiquement visibles les futures tables :

```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO metabase_reader;
```
