# Bien démarrer avec watsonx Orchestrate

Tutoriel pratique, en français, pour créer des agents IA avec IBM watsonx Orchestrate, sans code puis avec l'ADK. Il suit le parcours IBM Developer [Get started with watsonx Orchestrate](https://developer.ibm.com/learningpaths/get-started-watsonx-orchestrate/).

## Objectifs

- **Orchestrer plusieurs agents** spécialisés qui partagent le contexte.
- **Réutiliser** les agents prédéfinis du catalogue plutôt que tout construire.
- **Construire sans code** agents, bases de connaissances et workflows agentiques, en quelques minutes.
- **Atteindre les utilisateurs** sur WhatsApp et d'autres canaux.
- **Industrialiser avec l'ADK** : agents et workflows versionnés en code, importés en une commande.

## Programme

| Partie | Contenu |
| :--- | :--- |
| Bien démarrer | Essai gratuit, accès à l'instance, identifiants d'API |
| 1. Introduction | Orchestration d'agents, concepts clés |
| 2. Agents prédéfinis | Personnaliser et déployer des agents du catalogue |
| 3. Agents sans code | Un superviseur et deux spécialistes, exposés sur WhatsApp |
| 4. Workflows agentiques sans code | Extraction de passeport, branchement, formulaire, prompt génératif |
| 5. ADK | Hello World, import du système de la partie 3, Bob, workflow de la partie 4 en Python |

## Démarrer

Prérequis : une instance watsonx Orchestrate ([essai gratuit de 30 jours](https://www.ibm.com/account/reg/us-en/signup?formid=urx-54418)), [uv](https://docs.astral.sh/uv/).

## Agents et workflows (ADK)

| Projet | Partie | Description |
| :--- | :--- | :--- |
| [Earning Report Analyst](wxo/earnings_report_analyst/README.md) | 3 et 5.2 | Superviseur et deux analystes de résultats financiers (PepsiCo, Coca-Cola) |
| [Account Opening Agent](wxo/account_opening_agent/README.md) | 4 et 5.4 | Ouverture de compte : extraction de passeport, formulaire, confirmation générée |
