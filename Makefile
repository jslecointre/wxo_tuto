.DEFAULT_GOAL := help

.PHONY: help bob-help bob-developer bob-status bob-reset _bob-setup bob-orchestrate-activate earnings-docs wxo-import-earnings wxo-channel-whatsapp passport-images wxo-import-account-opening

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Bob targets (see 'make bob-help' for details):"
	@echo "  bob-developer             Set up .bob/ for the wxO agent Developer persona"
	@echo "  bob-status                Show which persona .bob/ is currently set up for"
	@echo "  bob-reset                 Remove .bob/skills, .bob/rules, .bob/rules-<mode>, .bob/mcp.json, .bob/custom_modes.yaml"
	@echo ""
	@echo "Watson Orchestrate targets (WXO_ENV_NAME/WXO_API_KEY/WXO_URL from the shell, else .env):"
	@echo "  bob-orchestrate-activate  Activate (or add) the Orchestrate env WXO_ENV_NAME"
	@echo ""
	@echo "Tutorial data:"
	@echo "  earnings-docs             Download the PepsiCo / Coca-Cola earnings documents for part 3 into data/earnings/"
	@echo "  wxo-import-earnings       Import wxo/earnings_report_analyst (knowledge bases + agents) into the active env"
	@echo "  wxo-channel-whatsapp      Create the WhatsApp (Twilio) channel for earning_report_analyst from TWILIO_* in .env"
	@echo "  passport-images           Download the 4 synthetic passport images for part 4 into data/passports/"
	@echo "  wxo-import-account-opening  Import wxo/account_opening_agent (flow tool + agent) into the active env"

# ---------------------------------------------------------------------------
# Bob (IBM Bob Shell) persona bootstrap.
#
# `make bob-<persona>` replaces .bob/skills/, .bob/rules/, .bob/rules-<mode>/, .bob/mcp.json and .bob/custom_modes.yaml
# with that persona's tools (.bob/ is generated; .bob/mcp.json is backed up first). Sources:
#   bob-skills/<name>/            skills
#   bob-rules/<file>.md           rules (ROOT_RULES -> repo root, BOB_RULES -> .bob/rules/)
#   bob-rules-<mode>/             per-mode rules (BOB_MODE_RULES, every persona) -> .bob/rules-<mode>/
#   bob-mcp/mcp.<persona>.json    MCP config with ${VAR} placeholders, filled from .env (else CHANGE_ME)
#   bob-modes/custom_modes.yaml   modes
# When the MCP config includes orchestrate-adk, the WXO_ENV_NAME environment is activated.
# Run from the repo root.
# ---------------------------------------------------------------------------

bob-help: ## List Bob personas and what each command sets up
	@echo "Bob persona setup — run from the repo root."
	@echo ""
	@echo "  make bob-developer       wxO agent builder: orchestrate-adk + ADK docs MCP servers, wxo-development skill, wxo rules"
	@echo "  make bob-status          Show which persona .bob/ is currently set up for"
	@echo "  make bob-reset           Remove .bob/skills, .bob/rules, .bob/rules-<mode>, .bob/mcp.json, .bob/custom_modes.yaml"
	@echo "  make bob-orchestrate-activate   Activate (or add) the Orchestrate env WXO_ENV_NAME (shell exports win over .env)"
	@echo ""
	@echo "The MCP config is a template (CHANGE_ME placeholders) — fill in real"
	@echo "credentials via .env (WXO_*) or edit .bob/mcp.json directly."

bob-developer: ## Set up .bob/ for the Developer persona
	@$(MAKE) --no-print-directory _bob-setup PERSONA=developer MODE=developer \
		SKILLS="wxo-development" \
		ROOT_RULES="wxo-implementation-guide.md" BOB_RULES="wxo-development.md"

# Built-in Bob modes whose bob-rules-<mode>/ folder is copied to .bob/rules-<mode>/ for every persona.
BOB_MODE_RULES := agent ask plan

# Internal: shared setup for bob-<persona> targets (PERSONA/MODE/SKILLS required; ROOT_RULES/BOB_RULES optional).
_bob-setup:
	@test -n "$(PERSONA)" || { echo "internal target — use make bob-<persona> instead" >&2; exit 1; }
	@mkdir -p .bob bob-mcp
	@if [ -f .bob/mcp.json ]; then cp .bob/mcp.json .bob/mcp.json.backup; fi
	@rm -rf .bob/skills .bob/rules $(addprefix .bob/rules-,$(BOB_MODE_RULES))
	@mkdir -p .bob/skills
	@for s in $(SKILLS); do \
		if [ -d "bob-skills/$$s" ]; then \
			cp -r "bob-skills/$$s" ".bob/skills/$$s"; \
		else \
			echo "warning: bob-skills/$$s not found, skipping" >&2; \
		fi; \
	done
	@for r in $(ROOT_RULES); do \
		if [ -f "bob-rules/$$r" ]; then \
			cp "bob-rules/$$r" "./$$r"; \
		else \
			echo "warning: bob-rules/$$r not found, skipping" >&2; \
		fi; \
	done
	@if [ -n "$(BOB_RULES)" ]; then mkdir -p .bob/rules; fi
	@for r in $(BOB_RULES); do \
		if [ -f "bob-rules/$$r" ]; then \
			cp "bob-rules/$$r" ".bob/rules/$$r"; \
		else \
			echo "warning: bob-rules/$$r not found, skipping" >&2; \
		fi; \
	done
	@for m in $(BOB_MODE_RULES); do \
		if [ -d "bob-rules-$$m" ]; then \
			cp -r "bob-rules-$$m" ".bob/rules-$$m"; \
		else \
			echo "warning: bob-rules-$$m not found, skipping" >&2; \
		fi; \
	done
	@tmpl="bob-mcp/mcp.$(PERSONA).json"; \
	if [ ! -f "$$tmpl" ]; then \
		echo "note: $$tmpl missing — writing an empty dummy config" >&2; \
		printf '{\n  "mcpServers": {}\n}\n' > "$$tmpl"; \
	fi; \
	UVX_PATH="$$(command -v uvx)" uv run python bob-modes/render_mcp_json.py "$$tmpl" .env .bob/mcp.json
	@if grep -q '"orchestrate-adk"' .bob/mcp.json; then \
		echo "  orchestrate-adk MCP server present — activating Watson Orchestrate environment"; \
		$(MAKE) --no-print-directory bob-orchestrate-activate || echo "warning: Orchestrate env not activated — .bob/ setup continues" >&2; \
	fi
	@uv run --with pyyaml python bob-modes/extract_mode.py "$(MODE)" bob-modes/custom_modes.yaml .bob/custom_modes.yaml
	@echo "$(PERSONA)" > .bob/.active_persona
	@echo "✔ .bob/ set up for persona: $(PERSONA)"
	@echo "  skills: $(SKILLS)"
	@if [ -n "$(ROOT_RULES)" ]; then echo "  root rules: $(ROOT_RULES) (copied to project root from bob-rules/)"; fi
	@if [ -n "$(BOB_RULES)" ]; then echo "  bob rules:  $(BOB_RULES) (copied to .bob/rules/ from bob-rules/)"; fi
	@echo "  mode rules: $(addprefix .bob/rules-,$(BOB_MODE_RULES)) (from bob-rules-<mode>/)"
	@echo "  mcp:    .bob/mcp.json (from bob-mcp/mcp.$(PERSONA).json, \$${VAR} placeholders filled from .env — any left as CHANGE_ME need adding there)"
	@echo "  mode:   .bob/custom_modes.yaml ($(MODE) only)"
	@if [ -f .bob/mcp.json.backup ]; then echo "  (previous .bob/mcp.json saved to .bob/mcp.json.backup)"; fi

bob-status: ## Show which persona .bob/ is currently configured for
	@if [ -f .bob/.active_persona ]; then \
		echo "Active persona: $$(cat .bob/.active_persona)"; \
	else \
		echo "No persona set up yet — run: make bob-developer"; \
	fi
	@echo "Skills installed:"
	@ls .bob/skills 2>/dev/null | sed 's/^/  - /' || echo "  (none)"
	@echo "Rules installed (.bob/rules):"
	@ls .bob/rules 2>/dev/null | sed 's/^/  - /' || echo "  (none)"
	@for m in $(BOB_MODE_RULES); do \
		echo "Rules installed (.bob/rules-$$m):"; \
		ls .bob/rules-$$m 2>/dev/null | sed 's/^/  - /' || echo "  (none)"; \
	done

bob-reset: ## Remove .bob/skills, .bob/rules, .bob/rules-<mode>, .bob/mcp.json, .bob/custom_modes.yaml, .bob/.active_persona
	@if [ -f .bob/mcp.json ]; then cp .bob/mcp.json .bob/mcp.json.backup; fi
	@rm -rf .bob/skills .bob/rules $(addprefix .bob/rules-,$(BOB_MODE_RULES)) .bob/mcp.json .bob/custom_modes.yaml .bob/.active_persona
	@echo "✔ .bob/ reset (previous mcp.json saved to .bob/mcp.json.backup if it existed)"
	@echo "  note: root-level rule files (e.g. wxo-implementation-guide.md) are not removed — delete manually if no longer needed"

# Shell exports (WXO_ENV_NAME, WXO_API_KEY, WXO_URL or WXO_API_URL) win over .env. An env missing from the
# local orchestrate config is added (ibm_iam) when a URL is known. Fails rather than leaving another env active.
bob-orchestrate-activate: ## Activate (adding it if needed) the Watson Orchestrate env named by WXO_ENV_NAME (shell, else .env)
	@dotenv() { grep -E "^$$1=" .env 2>/dev/null | tail -1 | cut -d= -f2-; }; \
	wxo_env=$${WXO_ENV_NAME:-$$(dotenv WXO_ENV_NAME)}; \
	wxo_key=$${WXO_API_KEY:-$$(dotenv WXO_API_KEY)}; \
	wxo_url=$${WXO_URL:-$${WXO_API_URL:-$$(dotenv WXO_URL)}}; \
	wxo_url=$${wxo_url:-$$(dotenv WXO_API_URL)}; \
	if [ -z "$$wxo_env" ]; then \
		echo "warning: WXO_ENV_NAME is not set (shell or .env) — skipping env activate" >&2; exit 0; \
	fi; \
	activate() { \
		if [ -n "$$wxo_key" ]; then uv run orchestrate env activate "$$wxo_env" --api-key "$$wxo_key"; \
		else uv run orchestrate env activate "$$wxo_env"; fi; \
	}; \
	echo "  activating Watson Orchestrate env: $$wxo_env"; \
	if ! activate 2>/dev/null; then \
		if COLUMNS=250 uv run orchestrate env list 2>/dev/null | grep -qE "^[[:space:]]*$$wxo_env[[:space:]]"; then \
			echo "error: env '$$wxo_env' exists but activation failed — WXO_API_KEY is probably invalid or expired" >&2; exit 1; \
		fi; \
		if [ -z "$$wxo_url" ]; then \
			echo "error: env '$$wxo_env' is not in the orchestrate config and no WXO_URL/WXO_API_URL is set to add it" >&2; exit 1; \
		fi; \
		echo "  env '$$wxo_env' not found — adding it ($$wxo_url)"; \
		uv run orchestrate env add -n "$$wxo_env" -u "$$wxo_url" --type ibm_iam && activate || { \
			echo "error: could not add/activate Watson Orchestrate env '$$wxo_env' — check WXO_* values" >&2; exit 1; }; \
	fi

earnings-docs: ## Download the PepsiCo / Coca-Cola earnings documents for part 3 into data/earnings/
	@./scripts/get-earnings-docs.sh data/earnings

# Synthetic passports from the SynID dataset (arXiv 2505.07540), as named in the part 4 tutorial:
# 1 and 2 train the document extractor, 3 (Polish) and 4 (Spanish) test the workflow.
PASSPORT_DIR ?= data/passports
PASSPORT_BASE := https://arxiv.org/html/2505.07540v1/extracted/6431687/images

passport-images: ## Download the 4 synthetic passport images for part 4 into data/passports/
	@mkdir -p $(PASSPORT_DIR)
	@set -e; for pair in passport-1.jpg:JT_polpp.jpg passport-2.png:JT_porpp.png \
		passport-3.png:poland-pass-print.png passport-4.png:JT_esppp.png; do \
		dest="$(PASSPORT_DIR)/$${pair%%:*}"; \
		if [ -s "$$dest" ]; then echo "  exists  $$dest"; continue; fi; \
		curl -fsSL -A "Mozilla/5.0" -o "$$dest" "$(PASSPORT_BASE)/$${pair#*:}"; \
		echo "  ok      $$dest"; \
	done

wxo-import-account-opening: ## Import wxo/account_opening_agent (flow tool + agent) into the active Watson Orchestrate env
	@$(MAKE) --no-print-directory bob-orchestrate-activate
	@uv run ./wxo/account_opening_agent/import-all.sh

wxo-import-earnings: ## Import wxo/earnings_report_analyst (knowledge bases + agents) into the active Watson Orchestrate env
	@$(MAKE) --no-print-directory bob-orchestrate-activate
	@uv run ./wxo/earnings_report_analyst/import-all.sh


# WhatsApp channel of the part 3 supervisor. Twilio credentials: shell exports win over .env.
# CHANNEL_ENV=live (default) deploys the agent first, as a live channel needs a deployed agent.
CHANNEL_AGENT ?= earning_report_analyst
CHANNEL_ENV ?= live

wxo-channel-whatsapp: ## Create (or update) the WhatsApp Twilio channel of earning_report_analyst and print its webhook (Event URL)
	@$(MAKE) --no-print-directory bob-orchestrate-activate
	@dotenv() { grep -E "^$$1=" .env 2>/dev/null | tail -1 | cut -d= -f2-; }; \
	sid=$${TWILIO_ACCOUNT_SID:-$$(dotenv TWILIO_ACCOUNT_SID)}; \
	token=$${TWILIO_AUTH_TOKEN:-$$(dotenv TWILIO_AUTH_TOKEN)}; \
	if [ -z "$$sid" ] || [ -z "$$token" ]; then \
		echo "error: TWILIO_ACCOUNT_SID / TWILIO_AUTH_TOKEN not set (shell or .env)" >&2; exit 1; \
	fi; \
	if [ "$(CHANNEL_ENV)" = "live" ]; then uv run orchestrate agents deploy -n $(CHANNEL_AGENT) || exit 1; fi; \
	uv run orchestrate channels create --agent-name $(CHANNEL_AGENT) --env $(CHANNEL_ENV) --type twilio_whatsapp \
		--name "WhatsApp Twilio Integration" --description "WhatsApp Twilio Integration" \
		--field account_sid="$$sid" --field twilio_authentication_token="$$token" || exit 1; \
	echo "Paste the Event URL above into Twilio: Messaging > Try it out > Send a WhatsApp message > Sandbox settings > When a message comes in (POST)"
