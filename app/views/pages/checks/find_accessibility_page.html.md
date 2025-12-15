## <%= t("checks.find_accessibility_page.type") %>

### Objectif

Trouver la présence de la déclaration d’accessibilité sur le site.

### Évaluation

Nous cherchons un lien vers la page d’accessibilité à partir de la page d’accueil et l’enregistrons pour les analyses suivantes.
D'abord depuis le lien de la mention, si existante, puis dans les liens présents dans la page d'accueil.

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
        <td><p class="fr-badge fr-badge--success"></p></td>
        <td><p>Réussi - Déclaration trouvée</p></td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--error"><%= t("checks.find_accessibility_page.not_found") %></p></td>
        <td> <p>Échec - Aucun lien vers la page d’accessibilité n’a été détecté </p></td>
      </tr>
    </tbody>
  </table>
</div>

<%= dsfr_notice(title: "Information", description: "Si cette vérification échoue, les tests liés à la déclaration seront annulés.") %>
