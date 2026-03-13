## <%= t("checks.run_axe_on_homepage.type")%>

### Objectif

Évaluer automatiquement la page d’accueil avec un outil de contrôle d’accessibilité et donner un score de réussite sur un ensemble de règles liées au RGAA.

### Évaluation

Nous lançons une analyse sur la page d’accueil et comptons les règles respectées, celles à vérifier, et les erreurs détectées.
Le score affiché correspond à la part de règles sans erreurs parmi les règles applicables à la page.
Afin de réaliser ces tests automatiques, nous utilisons l’outil [axe-core](https://github.com/dequelabs/axe-core).

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
        <td><p class="fr-badge fr-badge--success">100%</p></td>
        <td><p>Succès - Aucun échec détecté. Toutes les règles RGAA évaluées par axe-core sont validées.</p></td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--new">80%</p></td>
        <td><p>Bien - Entre 50% et 100%. Quelques erreurs mineures, mais la majorité des critères sont corrects.</p></td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--warning">30%</p></td>
        <td><p>Avertissement - Entre 1% et 50%. Plusieurs violations RGAA sont présentes et nécessitent une correction.</p></td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--error">0%</p></td>
        <td><p>Échec - Aucun critère n’est validé. Le site présente un grand nombre de non-conformités.</p></td>
      </tr>
    </tbody>
  </table>
</div>

### Remarque

Cette analyse met en évidence des problèmes courants (ex : langue de la page, titres, attributs ARIA, etc.).
Elle ne remplace pas un audit complet, mais fournit un indicateur rapide.
