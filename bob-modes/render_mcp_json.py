"""Render a bob-mcp/*.json template into .bob/mcp.json, substituting ${VAR}
placeholders from the shell environment, else from the .env file (same
precedence as `make bob-orchestrate-activate`). WXO_URL and WXO_API_URL are
interchangeable. Vars set in neither are left as the literal string CHANGE_ME
so the output stays usable (and greppable).

Usage: render_mcp_json.py <template.json> <.env> <output.json>
"""

import json
import os
import re
import sys

PLACEHOLDER = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}")

# Names accepted for the same value, tried in order.
ALIASES = {
    "WXO_URL": ["WXO_URL", "WXO_API_URL"],
    "WXO_API_URL": ["WXO_API_URL", "WXO_URL"],
}


def load_env(path):
    env = {}
    try:
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, value = line.partition("=")
                value = value.strip()
                if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                    value = value[1:-1]
                env[key.strip()] = value
    except FileNotFoundError:
        print(
            f"note: {path} not found — leaving all placeholders as CHANGE_ME",
            file=sys.stderr,
        )
    return env


def main():
    template_path, env_path, output_path = sys.argv[1:4]
    env = load_env(env_path)

    with open(template_path, encoding="utf-8") as f:
        text = f.read()

    missing = []

    def substitute(match):
        var = match.group(1)
        names = ALIASES.get(var, [var])
        value = next(
            (src[n] for src in (os.environ, env) for n in names if src.get(n)), None
        )
        if value is None or value == "":
            missing.append(var)
            value = "CHANGE_ME"
        return json.dumps(value)[1:-1]

    rendered = PLACEHOLDER.sub(substitute, text)

    json.loads(rendered)  # fail fast if substitution produced invalid JSON

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(rendered)

    if missing:
        print(
            f"note: not set in the shell or {env_path}, left as CHANGE_ME: {', '.join(sorted(set(missing)))}",
            file=sys.stderr,
        )


if __name__ == "__main__":
    main()
