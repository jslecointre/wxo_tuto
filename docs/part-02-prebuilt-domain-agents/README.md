---
title: 2. Agents de domaine prédéfinis
description: Personnaliser et déployer des agents de l'Agent Catalog
logo: images/ibm-blue-background.png
---

# 2. Agents de domaine prédéfinis

Suivez : [Prebuilt domain agents](https://developer.ibm.com/learningpaths/get-started-watsonx-orchestrate/prebuilt-domain-agents/).

## L'Agent Catalog

L'Agent Catalog propose des centaines d'agents et d'outils prédéfinis par domaine (RH, ventes, service client, finance, IT…). Chaque agent effectue des actions, récupère des informations ou raisonne sur des tâches complexes.

![Agent Catalog de watsonx Orchestrate](https://developer.ibm.com/developer/default/articles/prebuilt-domain-agents-watsonx-orchestrate/images/agent-catalog-v2.png)

Ces agents fonctionnent nativement avec les applications de l'entreprise (Coupa, Dropbox, Dun & Bradstreet, Salesforce, Outlook, Gmail, ServiceNow, SAP SuccessFactors…) : vous tirez parti de vos systèmes existants sans développement spécifique.

![Applications prises en charge](https://developer.ibm.com/developer/default/articles/prebuilt-domain-agents-watsonx-orchestrate/images/prebuilt-apps.png)

## Exemple RH : Employee Support Manager

L'agent **Employee Support Manager (SAP SuccessFactors)** est un superviseur : il interprète les demandes RH des employés et les transmet à l'agent spécialisé le plus adapté.

### 1. Configurer la connexion

Configurez la connexion à SAP SuccessFactors (authentification, accès API) en suivant [Connecter les applications des agents prédéfinis](https://www.ibm.com/docs/en/watsonx/watson-orchestrate/base?topic=credentials-connecting-apps-from-prebuilt-agents).

### 2. Construire et déployer l'agent

1. Dans l'**Agent Catalog**, filtrez par **Type** : *Agents*, **Categories** : *HR*, **Apps** : *SAP SuccessFactors*.

    ![Agent Catalog filtré](https://developer.ibm.com/developer/default/articles/prebuilt-domain-agents-watsonx-orchestrate/images/sap-filter.png)

1. Recherchez *Employee Support Manager* et sélectionnez-le.

    ![Employee Support Manager et ses agents](https://developer.ibm.com/developer/default/articles/prebuilt-domain-agents-watsonx-orchestrate/images/employee-support-manager-agents.png)

1. Cliquez sur **Use as template**. Vous pouvez renommer l'agent avec l'icône crayon.
1. Dans **Toolset > Agents**, consultez les agents collaborateurs : Compensation, Employee Email, Employee Visa, Employee Personal Info, Employee Phone, Employee Address.

    ![Agents collaborateurs](https://developer.ibm.com/developer/default/articles/prebuilt-domain-agents-watsonx-orchestrate/images/sf-collab-agents.png)

1. Ajustez si besoin le **Behavior** (comportement de l'agent), le modèle de raisonnement (menu **Model**) et les canaux (chat web, Microsoft Teams, WhatsApp, Slack…).
1. Cliquez sur **Deploy**, vérifiez le récapitulatif (profil, outils, collaborateurs, comportement, connexion SuccessFactors), puis confirmez avec **Deploy**.

    ![Récapitulatif avant déploiement](https://developer.ibm.com/developer/default/articles/prebuilt-domain-agents-watsonx-orchestrate/images/deployment-summary.png)

### 3. Tester l'agent

Ouvrez **Chat**, sélectionnez *SuccessFactors Employee Support Manager* dans la liste des agents, puis essayez :

| Prompt | Ce qui se passe |
| :--- | :--- |
| `Show me payslips for jadannb@test.com for 2018-01-01 to 2018-01-31` | Délégué à l'agent *Compensation*, qui appelle deux outils : recherche de l'ID utilisateur, puis des bulletins de paie |
| `Show me the current compensation details` | L'agent garde le contexte : même employé, sans le redemander |
| `Update the phone number of jadannb@test.com to +1 555 0100` | Délégué à l'agent *employee_phone* : l'agent agit, il ne fait pas que lire |
| `Which employees in my department have a visa expiring soon? Send them a reminder email.` | Requête complexe : environ 9 étapes de raisonnement entre *organization_structure*, *employee_visa* et le superviseur |

Cliquez sur **Show Reasoning** pour voir quels agents et outils ont été appelés.

![Raisonnement de l'agent pour les bulletins de paie](https://developer.ibm.com/developer/default/articles/prebuilt-domain-agents-watsonx-orchestrate/images/payslip-reasoning.png)

/// tip | Personnaliser le comportement
Dans **Manage agents**, modifiez le **Behavior** pour que l'agent réponde uniquement en espagnol (ou en français), redéployez, puis reposez une question.
///

/// note | Autre exemple : la prospection commerciale
Le même principe s'applique au *Sales Prospecting Agent* (Salesforce, Dun & Bradstreet, Seismic, Outlook) : voir l'[article IBM](https://developer.ibm.com/learningpaths/get-started-watsonx-orchestrate/prebuilt-domain-agents/) et les [étapes de configuration](../references.md#connexions-des-agents-predefinis).
///

## En résumé

Les agents prédéfinis combinent automatisation structurée et raisonnement pour orchestrer des processus en plusieurs étapes, sans code. Ils réduisent l'effort manuel, améliorent la précision et accélèrent la mise en œuvre, tout en restant transparents (**Show Reasoning**) et contrôlables (**Behavior**, modèle, canaux).

Pour aller plus loin : explorez d'autres agents de l'Agent Catalog, puis créez vos propres agents [sans code](../part-03-no-code-agents/README.md) ou [avec l'ADK](../part-05-adk/README.md).
