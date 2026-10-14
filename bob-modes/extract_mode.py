"""Extract a single Bob custom mode by slug into its own YAML file.

Used by the Makefile's bob-* persona-setup targets so .bob/custom_modes.yaml ends
up containing only the active persona's mode, never all of them.
"""

import sys

import yaml


def main() -> None:
    if len(sys.argv) != 4:
        print(
            "usage: extract_mode.py <slug> <source.yaml> <dest.yaml>", file=sys.stderr
        )
        raise SystemExit(2)

    slug, source_path, dest_path = sys.argv[1:4]

    with open(source_path) as f:
        modes = yaml.safe_load(f)["customModes"]

    matches = [m for m in modes if m["slug"] == slug]
    if not matches:
        print(f"mode '{slug}' not found in {source_path}", file=sys.stderr)
        raise SystemExit(1)

    with open(dest_path, "w") as f:
        yaml.safe_dump({"customModes": matches}, f, allow_unicode=True, sort_keys=False)


if __name__ == "__main__":
    main()
