## <%= t("checks.analyze_accessibility_page.type")%>

### Objectif

Vérifier que la page d’accessibilité fournit les informations essentielles :

- Date de l’audit
- Date de mise à jour
- Taux de conformité
- Référence au référentiel (RGAA/WCAG)
- Mention de l’article 47 de la loi de 2005
- Nom de l’organisme ayant réalisé l’audit

Pour que la déclaration soit considérée comme complète, les informations suivantes doivent être présentes :

- Date de l'audit
- Taux de conformité
- Mention de l'article 47 de la loi du 11 février 2005

### Évaluation

Nous analysons la page de la déclaration et recherchons ces informations dans les sections suivantes :

- Déclaration d’accessibilité
- État de conformité
- Établissement de cette déclaration d’accessibilité
- Résultats des tests

Les dates peuvent être au format « 12 février 2024 » ou « 12/02/2024 ».
Le taux de conformité est cherché en pourcentage (ex : « 78 % des critères »).
La référence au standard peut-être « RGAA » ou « WCAG ».

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
        <td><p class="fr-badge fr-badge--success">78%</p></td>
        <td> <p>Réussi - Déclaration complète (la date d’audit, le taux de conformité et la mention de l’article 47 sont présents). Le badge affiche le taux (ex : « 78% »)</p></td>
      </tr>
      <tr>
        <td><p class="fr-badge fr-badge--warning"><%= t("checks.analyze_accessibility_page.missing_data") %></p></td>
        <td> <p>Avertissement - Déclaration incomplète (des informations clés manquent : date de l'audit, taux de conformité, mention de l’article 47) </p></td>
      </tr>
    </tbody>
  </table>
</div>
