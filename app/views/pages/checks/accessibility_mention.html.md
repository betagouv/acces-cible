## <%= t("checks.accessibility_mention.type")%>

### Objectif

Vérifier que la page mentionne clairement le niveau de conformité déclaré : « non conforme »,
« partiellement conforme » ou « totalement conforme ».

### Évaluation

Le système cherche, dans la page d'accueil, une mention d’accessibilité du type :

- non conforme
- partiellement conforme
- totalement conforme

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
        <td><p class="fr-badge fr-badge--success"><%= t("checks.accessibility_mention.mentions.totalement") %></p></td>
        <td>Trouvée - <%= t("checks.accessibility_mention.mentions.totalement") %></td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--new"><%= t("checks.accessibility_mention.mentions.partiellement") %></p></td>
        <td>Trouvée - <%= t("checks.accessibility_mention.mentions.partiellement") %></td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--warning"><%= t("checks.accessibility_mention.mentions.non") %></p></td>
        <td>Trouvée - <%= t("checks.accessibility_mention.mentions.non") %></td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--error"><%= t("checks.accessibility_mention.mentions.none") %></p></td>
        <td><%= t("checks.accessibility_mention.mentions.none") %></td>
      </tr>
    </tbody>
  </table>
</div>

### Exemples valides

- **accessibilité : non conforme** - format attendu
- **accessibilité (partiellement conforme)** - parenthèses acceptées
- **accessibilité du site : totalement conforme** - “du site” accepté
- **ACCESSIBILITE : NON CONFORME** - casse/accents ignorés

### Exemples non valides

- **Accessibillité (non conforme)** - faute dans “accessibilité”
- **accessibilité conforme** - formulation incomplète
- **accessibilité : peu conforme** - formulation non prévue
