#!/usr/bin/env bash
# Import the Account Opening Agent (ADK version) into the active watsonx Orchestrate env.
# Order matters: the agentic workflow tool first, then the agent that uses it.
set -euo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

orchestrate tools import -k flow -f "${SCRIPT_DIR}/tools/create_new_bank_account_flow.py"
orchestrate agents import -f "${SCRIPT_DIR}/agents/account_opening_agent.yaml"
