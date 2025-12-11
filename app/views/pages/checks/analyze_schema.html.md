## <%= Check.human("checks.analyze_schema.type")%>

### Objectif

Vérifier la présence d’un lien vers le schéma d’accessibilité et que la période indiquée couvre l’année en cours.

### Évaluation

Nous cherchons un lien dont l’intitulé mentionne un « schéma » d’accessibilité (annuel ou pluriannuel) et une plage d'années.
Le lien doit fonctionner et la période doit inclure l’année actuelle.
Un simple texte sans lien dans la déclaration est relevé en tant qu'avertissement.

### Badges affichés dans le tableau du site

<div class="fr-table">
  <table>
    <thead>
      <tr>
        <th scope="col">Badges</th>
        <th scope="col">Résultat</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><p class="fr-badge fr-badge--success"><%= Check.human("checks.analyze_schema.all_passed") %></p></td>
        <td>Réussi - Lien trouvé et valide (sur une plage de 3 ans incluant l'année en cours)</td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--warning"><%= Check.human("checks.analyze_schema.invalid_years") %></p></td>
        <td>Avertissement - Lien trouvé et valide, mais les années précisées sont invalides (anciennes/incohérentes) </td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--warning"><%= Check.human("checks.analyze_schema.schema_in_main_text") %></p></td>
        <td>Avertissement - Schéma trouvé, mais seulement mentionné dans le texte</td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--error"><%= Check.human("checks.analyze_schema.nothing_found") %></p></td>
        <td> Erreur - Aucun lien ni mention de schéma n'a été trouvé </td>
      </tr>
    </tbody>
  </table>
</div>

### Exemples

##### Exemples valides

- **schéma pluriannuel d’accessibilité numérique 2024** - format attendu
- **schéma pluriannuel de mise en accessibilité 2023–2025** - “mise en accessibilité” accepté
- **schéma pluriannuel RGAA 2022–2024** - "RGAA" accepté
- **schéma d’accessibilité pluriannuel 2022–2024** - "pluriannuelle" accepté
- **schéma annuel d’accessibilité 2024** - "annuel" accepté
- **SCHEMA PLURIANNUEL D’ACCESSIBILITE 2025** - casse/accents ignorés

##### Exemples non valides

- **schéma pluriannuel d'accessibillité numérique 2024** - faute dans “accessibilité”
- **schéma annuel accessibilité 2023** - manque “d’accessibilité”
- **schéma pluriannuel d’accessibilité 24–25** - années non valides (pas au format 4 chiffres)
- **accessibilité - schéma 2024** - forme incomplète (manque “numérique” ou “annuel”)

##### Exemples d’années valides

- **2025** - année courante
- **2024 - 2026** - plage qui contient l’année courante

##### Exemples d’années non valides

- **2024** - pas l’année courante
- **2023 - 2027** - plage de plus de 3 ans
- **2028 - 2029** - plage hors de l’année courante
