## <%= t("checks.analyze_plan.type")%>

### Objectif

Vérifier la présence d’un lien vers un plan d’action annuel lié à l’accessibilité, correctement daté et joignable à l'adresse indiquée.

### Évaluation

Nous cherchons un lien dont l’intitulé évoque un « plan annuel » ou un « plan d’action » avec une année.
Le lien doit fonctionner et l’année indiquée doit correspondre à l’année en cours, précédente ou prochaine.
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
        <td><p class="fr-badge fr-badge--success"><%= t("checks.analyze_plan.all_passed") %></p></td>
        <td>Réussi - Lien trouvé et valide</td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--warning"><%= t("checks.analyze_plan.invalid_year") %></p></td>
        <td>Avertissement - Lien trouvé et valide, mais les années précisées sont invalides (anciennes/incohérentes) </td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--warning"><%= t("checks.analyze_plan.in_main_text") %></p></td>
        <td>Avertissement - Plan trouvé, mais seulement mentionné dans le texte</td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--error"><%= t("checks.analyze_plan.nothing_found") %></p></td>
        <td> Erreur - Aucun lien ni mention de plan n'a été trouvé </td>
      </tr>
    </tbody>
  </table>
</div>

### Exemples valides

- **plan annuel d’accessibilité numérique 2024** - format attendu
- **plan annuel de mise en accessibilité 2023–2024** - tiret accepté
- **plan annuel 2024** - forme courte acceptée
- **plan d’action 2025** - “d’action” accepté
- **plan d’actions 2024–2025** - pluriel accepté
- **plan 2024 d’action** - ordre accepté
- **PLAN ANNUEL D’ACCESSIBILITE 2025** - casse/accents ignorés

### Exemples non valides

- **plan accessibilité 2024** - formulation incomplète
- **plan d'accesibilité 2025** - faute dans “accessibilité”
- **plan annuel mise accessibilité 2024** - syntaxe incorrecte
