## <%= Check.human("checks.language_indication.type")%>

### Objectif

Vérifier que la page indique sa langue (par exemple « fr » pour français) et que cette indication correspond bien au contenu réel.
Sans indication, ou avec une indication différente du langage utilisé, certains lecteurs d'écran peuvent mal prononcer le contenu.

### Évaluation

Nous analysons l’indication de langue de la page et nous comparons avec la langue détectée automatiquement dans le texte.

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
        <td><p class="fr-badge fr-badge--success">FR</p></td>
        <td> Réussi - La langue de la page correspond à celle indiquée </td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--warning">EN</p></td>
        <td> Avertissement - Une langue est indiquée, mais ne correspond pas à la langue de la page </td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--error"><%= Check.human("checks.language_indication.empty") %></p></td>
        <td>Échec - Aucune indication n'a été trouvée </td>
      </tr>
    </tbody>
  </table>
</div>
