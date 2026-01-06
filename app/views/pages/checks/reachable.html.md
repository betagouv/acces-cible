## <%= t("checks.reachable.type")%>

### Objectif

Vérifier que la page d’accueil du site est joignable.

### Évaluation

Nous tentons de joindre le site et de scanner la page d’accueil.
Si le site est joignable, il renvoie une réponse OK (code HTTP 200) et du HTML valide.
Le site est considéré comme joignable et nous pouvons l'analyser.

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
        <td><p class="fr-badge fr-badge--success"><%= t("checks.reachable.reachable") %></p></td>
        <td> Réussi - Le site est joignable </td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--info"><%= t("checks.reachable.redirected") %></p></td>
        <td> Réussi - La redirection est signalée </td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--error">Erreur</p></td>
        <td>Échec - Le site n'est pas joignable ou renvoie une erreur.</td>
      </tr>
    </tbody>
  </table>
</div>

<%= dsfr_notice(title: "Information", description: "Si cette vérification échoue, tous les tests seront annulés.") %>
