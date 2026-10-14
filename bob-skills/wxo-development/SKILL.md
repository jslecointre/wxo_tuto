---
name: wxo-development
description: Guidelines for developing IBM watsonx Orchestrate (wxo) agents, tools, and flows with the watsonx Orchestrate ADK. Use this skill whenever creating, editing, importing, or troubleshooting wxo/ADK projects — agent YAML configs, Python `@tool` functions, `@flow` flow builders, KVP document-processing schemas, credential/connection setup, or `import-all.sh` CLI import scripts. Trigger on mentions of "watsonx Orchestrate", "wxo", "orchestrate ADK", `ibm_watsonx_orchestrate`, `orchestrate` CLI, agent_builder, flow_builder, or DocProc/KVP schemas.
---

# watsonx Orchestrate (wxO) Development

Guardrails for building IBM watsonx Orchestrate ADK projects: agents, tools, and
flows. this skill applies when a task asks for a new or edited wxO ADK project

## Before writing any code

1. **Read the reference guide.** `wxo-implementation-guide.md` at the repo
   root is the canonical source of truth — standard project structure, the
   four implementation patterns (simple tool flow, document processing, user
   activity, multi-agent collaboration), full code examples, and the Mermaid
   diagram conventions expected in READMEs. Read it (or the relevant section)
   before generating agent/tool/flow code.
2. **Use the MCP servers when connected.** Two ADK-related servers may be
   available in the session:
   - `orchestrate-adk` — programmatic ADK actions (`create_tool`,
     `import_agent`/`import_tool`, `export_agent`/`export_tool`, `list_tools`,
     `chat_with_agent`, etc.). Prefer the `orchestrate` CLI for imports per
     the rule below, but this server is useful for inspection, chat-testing,
     and export/import without a shell.
   - `watsonx-orchestrate-adk-docs` — search and retrieval over the official
     ADK documentation site. Use it to confirm API references or examples
     that aren't already covered in the implementation guide, rather than
     guessing.
   If neither is registered for the current Claude Code session, they need
   adding to this project's `.mcp.json` (there isn't one at the repo root
   today).

## Project structure (ADK convention)

Every wxo example/project follows this layout — use it for new projects:

```
project_name/
├── __init__.py
├── README.md              # architecture + workflow Mermaid diagrams
├── main_flow.py            # only needed if the project has flows
├── import-all.sh
├── tools/
│   ├── __init__.py
│   ├── <tool_name>.py      # @tool-decorated Python functions
│   └── <flow_name>.py      # @flow-decorated flow builders
├── agents/
│   └── <agent_name>.yaml
└── generated/
    └── flow_spec.json
```

## Non-negotiable rules

- **Flow function signature** — always `def build_<flow_name>(aflow: Flow) -> Flow:`.
  Parameter must be named `aflow` typed `Flow`; function name must start with
  `build_`; must return `Flow`. Never invent another signature.
- **Agent YAML required fields** — every agent config must include
  `spec_version: v1`, `kind: native`, `name`, `description`, `instructions`,
  `llm`, `style`, and `tools`. Missing any of these causes import errors.
- **Import via CLI only** — use the `orchestrate` CLI, never a custom Python
  import script:
  - `orchestrate tools import -k python -f <tool.py>`
  - `orchestrate tools import -k flow -f <flow.py>`
  - `orchestrate agents import -f <agent.yaml>`
- **Document-upload flows** — when a flow takes a document input
  (`DocProcInput`), the agent must invoke the flow tool directly; it cannot
  ask the user to upload first and pass the file in. The flow's `docproc`
  node handles the upload prompt itself.
- **KVP schemas** — build them with `DocProcKVPSchema` / `DocProcField`
  classes from `ibm_watsonx_orchestrate.flow_builder.types`, never plain
  dicts.
- **Pydantic models** — always defined as explicit classes; never use
  dynamic `type(...)` construction (breaks with "non-annotated attribute"
  errors).
- **Credentials** — declare with `expected_credentials` (plural) on `@tool`,
  passing a list of `ExpectedCredentials(app_id=..., type=ConnectionType.…)`
  objects — not `expect_credentials`, not plain dicts, and no unsupported
  `fields=` kwarg.
- **Flow output-mapping expressions** are single-line Python only — no
  function definitions, no calls to functions defined elsewhere in the flow
  file. Use list comprehensions / inline logic.
- **Keep tools focused** — one responsibility per tool; separate tools,
  flows, and agent config; reuse common utilities instead of duplicating.

## Implementation patterns

Pick the closest match before generating code (full examples in the guide):

| Pattern | Use case | Key pieces |
|---|---|---|
| Simple Tool Flow | basic retrieval/processing | `tools/*.py` + `agents/*.yaml` |
| Document Processing Flow | extract structured data from PDFs/images | KVP schema tool + `docproc` node |
| User Activity Flow | interactive multi-step input collection | `user_activity` node |
| Multi-Agent Collaboration | complex tasks split across specialists | per-agent tool files + coordinator agent |

## README requirement

Every project/example needs a `README.md` with:
- Overview
- **Architecture diagram** (Mermaid `graph TB`): User → Agent → Flow → Tools/Services
- **Workflow diagram** (Mermaid `flowchart TD`), one per flow, START → END,
  all nodes labeled, branches labeled for conditional logic
- Usage (chat UI and programmatic)
- Expected inputs/outputs, prerequisites

## Testing

- **Chat UI**: `./import-all.sh` then `orchestrate chat start`, select the agent.
- **Programmatic**: `export PYTHONPATH=<ADK>/src:<ADK>` then `python3 main_flow.py`.

For anything not covered above — full code samples, the complete document
processing KVP-structure walkthrough, credential type reference, prompt-node
requirements — read `wxo-implementation-guide.md` at the repo root.
