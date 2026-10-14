---
title: 5.2 Importer le système Earning Report Analyst
description: Importer avec la CLI orchestrate les bases de connaissances et les agents de la partie 3
logo: images/ibm-blue-background.png
---

# 5.2 Importer le système Earning Report Analyst

Le système multi-agents de la [partie 3](../part-03-no-code-agents/README.md), créé sans code, existe aussi en YAML dans `wxo/earnings_report_analyst/`. Vous allez l'importer pas à pas avec la CLI `orchestrate` de l'ADK.

Vous allez :

1. Vous connecter à votre instance watsonx Orchestrate.
1. Lire les fichiers YAML des bases de connaissances et des agents.
1. Importer les bases de connaissances, puis les agents.
1. Tester le superviseur en ligne de commande.

/// tip | Automatisé avec make
Chaque étape a son équivalent `make` (voir le [tableau en fin de page](#equivalents-make)). Pour apprendre, tapez les commandes `orchestrate` vous-même.
///

## Le projet

```text
wxo/earnings_report_analyst/
├── knowledge_bases/
│   ├── pepsico_earnings_kb.yaml
│   └── coca_cola_earnings_kb.yaml
├── agents/
│   ├── pepsico_earning_report_analyst.yaml
│   ├── coca_cola_earning_report_analyst.yaml
│   └── earning_report_analyst.yaml      # superviseur
└── import-all.sh
```

| Interface (partie 3) | YAML (ADK) |
| :--- | :--- |
| **Knowledge** : fichiers téléversés + description | `kind: knowledge_base`, `documents`, `description` |
| Base de connaissances d'un agent | `knowledge_base: [<nom>]` dans l'agent |
| **Toolset > Agents** (collaborateurs) | `collaborators: [<agent>, …]` |
| **Show Agent** désactivé | `hidden: true` |
| **Model** | `llm` |
| **Behavior** | `instructions` |

## Étape 1. Préparer l'environnement

Toutes les commandes se lancent depuis la racine du dépôt, avec `uv run` (ou dans l'environnement virtuel activé).

1. Vérifiez l'ADK :

    ```shell
    uv run orchestrate --help
    ```

1. Ajoutez votre instance (une seule fois) puis activez-la avec votre clé d'API (voir [Bien démarrer](../getting-started/README.md)) :

    /// tab | IBM Cloud

    ```shell
    uv run orchestrate env add -n wxo-tuto-1510 -u "$WXO_URL" --type ibm_iam
    uv run orchestrate env activate wxo-tuto-1510 --api-key "$WXO_API_KEY"
    ```

    ///

    /// tab | AWS

    ```shell
    uv run orchestrate env add -n wxo-aws -u "$WXO_URL" --type mcsp
    uv run orchestrate env activate wxo-aws --api-key "$WXO_API_KEY"
    ```

    ///

    ```shell
    uv run orchestrate env list      # l'environnement actif est marqué
    ```

    /// note
    Le jeton expire au bout d'un certain temps : relancez `orchestrate env activate` si une commande répond *token is missing or expired*.
    ///

1. Téléchargez les 8 documents financiers dans `data/earnings/` :

    ```shell
    make earnings-docs
    ```

1. Vérifiez qu'un modèle de la liste correspond au champ `llm` des agents (`groq/openai/gpt-oss-120b`) :

    ```shell
    uv run orchestrate models list
    ```

## Étape 2. Lire les fichiers YAML

**Une base de connaissances** : les chemins des documents sont relatifs au fichier YAML.

```yaml title="knowledge_bases/pepsico_earnings_kb.yaml"
spec_version: v1
kind: knowledge_base
name: pepsico_earnings_kb
description: >-
  PepsiCo quarterly earnings press releases and prepared management remarks for Q2 2025 and Q2 2020. ...
documents:
  - ../../../data/earnings/pepsico/pepsico-q2-2025-press-release.pdf
  - ../../../data/earnings/pepsico/pepsico-q2-2025-remarks.pdf
  - ../../../data/earnings/pepsico/pepsico-q2-2020-press-release.pdf
  - ../../../data/earnings/pepsico/pepsico-q2-2020-remarks.pdf
```

**Un agent spécialiste** : masqué, relié à sa base de connaissances.

```yaml title="agents/pepsico_earning_report_analyst.yaml"
spec_version: v1
kind: native
name: pepsico_earning_report_analyst
display_name: PepsiCo Earning Report Analyst
description: >-
  Answers PepsiCo earnings questions by analyzing PepsiCo earnings releases, ...
instructions: |-
  You are a financial analyst specialized in PepsiCo earnings.
  ...
llm: groq/openai/gpt-oss-120b
style: default
hidden: true
collaborators: []
tools: []
knowledge_base:
  - pepsico_earnings_kb
```

**Le superviseur** : visible, avec les deux spécialistes comme collaborateurs.

```yaml title="agents/earning_report_analyst.yaml"
spec_version: v1
kind: native
name: earning_report_analyst
display_name: Earning Report Analyst
...
collaborators:
  - pepsico_earning_report_analyst
  - coca_cola_earning_report_analyst
tools: []
```

## Étape 3. Importer les bases de connaissances

```shell
uv run orchestrate knowledge-bases import -f wxo/earnings_report_analyst/knowledge_bases/pepsico_earnings_kb.yaml
uv run orchestrate knowledge-bases import -f wxo/earnings_report_analyst/knowledge_bases/coca_cola_earnings_kb.yaml
```

Les documents sont téléversés puis indexés. Suivez l'indexation jusqu'à ce que le statut indique que la base est prête :

```shell
uv run orchestrate knowledge-bases status -n pepsico_earnings_kb
uv run orchestrate knowledge-bases status -n coca_cola_earnings_kb
uv run orchestrate knowledge-bases list
```

## Étape 4. Importer les agents

L'ordre compte : un agent ne peut référencer que des bases de connaissances et des collaborateurs **déjà importés**. Importez donc les spécialistes avant le superviseur.

```shell
uv run orchestrate agents import -f wxo/earnings_report_analyst/agents/pepsico_earning_report_analyst.yaml
uv run orchestrate agents import -f wxo/earnings_report_analyst/agents/coca_cola_earning_report_analyst.yaml
uv run orchestrate agents import -f wxo/earnings_report_analyst/agents/earning_report_analyst.yaml
```

```shell
uv run orchestrate agents list -k native
```

## Étape 5. Tester

En ligne de commande, avec la trace de raisonnement (délégation aux spécialistes) :

```shell
uv run orchestrate chat ask -n earning_report_analyst --include-reasoning \
  "In one table, list the Q2 2025 organic revenue growth and main performance driver for PepsiCo and Coca-Cola, using both companies' earnings releases and transcripts"
```

Sans question, `orchestrate chat ask -n earning_report_analyst` ouvre une conversation interactive.

Dans l'interface : **Chat** > *Earning Report Analyst* (les spécialistes n'apparaissent pas, ils sont masqués), puis **Show Reasoning**.

## Étape 6. Exposer le superviseur sur WhatsApp

Équivalent CLI de l'[étape 5 de la partie 3](../part-03-no-code-agents/README.md#etape-5-exposer-le-superviseur-sur-whatsapp-optionnel). Prérequis : un compte [Twilio](https://www.twilio.com/) avec le sandbox WhatsApp, et dans `.env` :

```shell title=".env"
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

1. Chargez les variables dans le terminal :

    ```shell
    set -a; source .env; set +a
    ```

1. Un canal **live** ne fonctionne qu'avec un agent déployé : déployez le superviseur.

    ```shell
    uv run orchestrate agents deploy -n earning_report_analyst
    ```

1. Créez le canal WhatsApp (type `twilio_whatsapp`) :

    ```shell
    uv run orchestrate channels create \
      --agent-name earning_report_analyst --env live --type twilio_whatsapp \
      --name "WhatsApp Twilio Integration" --description "WhatsApp Twilio Integration" \
      --field account_sid="$TWILIO_ACCOUNT_SID" \
      --field twilio_authentication_token="$TWILIO_AUTH_TOKEN"
    ```

    La commande affiche l'**Event URL** du canal : c'est le webhook à donner à Twilio. Si un canal du même nom existe déjà, il est mis à jour.

1. Vérifiez le canal :

    ```shell
    uv run orchestrate channels list-channels --agent-name earning_report_analyst --env live
    ```

1. Dans la console Twilio, **Messaging > Try it out > Send a WhatsApp message > Sandbox settings** : collez l'Event URL dans **When a message comes in** (méthode **POST**), puis **Save**.
1. Testez depuis WhatsApp comme à l'[étape 6 de la partie 3](../part-03-no-code-agents/README.md#etape-6-tester-depuis-whatsapp).

/// warning | Secrets
Ne collez jamais l'Auth Token directement dans une commande ou un fichier versionné : passez par `.env`, qui est ignoré par git.
///

## Modifier et nettoyer

- **Modifier un agent** : éditez son YAML et relancez `orchestrate agents import -f <fichier>` : l'agent existant est mis à jour (ajoutez `--safe` pour demander une confirmation).
- **Récupérer un agent modifié dans l'interface** :

    ```shell
    uv run orchestrate agents export -n earning_report_analyst -k native -o earning_report_analyst.zip
    ```

- **Tout supprimer** (superviseur d'abord, puis spécialistes et bases de connaissances) :

    ```shell
    uv run orchestrate channels delete --agent-name earning_report_analyst --env live -t twilio_whatsapp -n "WhatsApp Twilio Integration"
    uv run orchestrate agents remove -n earning_report_analyst -k native
    uv run orchestrate agents remove -n pepsico_earning_report_analyst -k native
    uv run orchestrate agents remove -n coca_cola_earning_report_analyst -k native
    uv run orchestrate knowledge-bases remove -n pepsico_earnings_kb
    uv run orchestrate knowledge-bases remove -n coca_cola_earnings_kb
    ```

## Équivalents make

| Étape | Commandes `orchestrate` | `make` |
| :--- | :--- | :--- |
| 1. Environnement | `env add` + `env activate` | `make bob-orchestrate-activate` |
| 1. Documents | – | `make earnings-docs` |
| 3 et 4. Import | `knowledge-bases import` puis `agents import` (×3) | `make wxo-import-earnings` |
| 6. WhatsApp | `agents deploy` puis `channels create --type twilio_whatsapp` | `make wxo-channel-whatsapp` |
