## <%= t("checks.accessibility_page_heading.type")%></h2>

### Objectif

Vérifier que la page d’accessibilité contient les titres attendus, dans un ordre précis et avec les bons niveaux de titres HTML.

### Évaluation

Nous comparons les titres présents sur la page avec une liste attendue.
Nous tolérons de légères variations d’intitulé.

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
        <td><p class="fr-badge fr-badge--success">90%</p></td>
        <td> <p>Réussi - De 90% à 100%, la majorité des titres sont présents, correctement hiérarchisés et ordonnés</p></td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--warning">60%</p></td>
        <td> <p>Avertissement - De 60% à 90%, certains titres sont présents, correctement hiérarchisés et ordonnés </p></td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--error">40%</p></td>
        <td> <p>Échec - De 0% à 40%, peu de titres sont présents et/ou sont mal hiérarchisés et ordonnés </p></td>
      </tr>
    </tbody>
  </table>
</div>
