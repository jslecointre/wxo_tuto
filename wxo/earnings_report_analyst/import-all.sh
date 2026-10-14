#!/usr/bin/env bash
# Import the Earning Report Analyst multi-agent system into the active watsonx Orchestrate env.
# Order matters: knowledge bases, then the specialist agents, then the supervisor that uses them.
set -euo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

for kb in pepsico_earnings_kb.yaml coca_cola_earnings_kb.yaml; do
  orchestrate knowledge-bases import -f "${SCRIPT_DIR}/knowledge_bases/${kb}"
done

for agent in pepsico_earning_report_analyst.yaml coca_cola_earning_report_analyst.yaml earning_report_analyst.yaml; do
  orchestrate agents import -f "${SCRIPT_DIR}/agents/${agent}"
done

echo "Check ingestion with: orchestrate knowledge-bases status -n pepsico_earnings_kb (and coca_cola_earnings_kb)"
