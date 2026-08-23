#!/usr/bin/env python3
"""Validate bundled passages and optionally compare them with official bsb.txt."""

from __future__ import annotations

import json
import pathlib
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
PASSAGES_FILE = ROOT / "Passages.js"


def load_passages() -> list[dict[str, str]]:
    source = PASSAGES_FILE.read_text(encoding="utf-8")
    start = source.index("[")
    end = source.rindex("]") + 1
    return json.loads(source[start:end])


def load_bsb(path: pathlib.Path) -> dict[str, str]:
    rows: dict[str, str] = {}
    with path.open(encoding="utf-8-sig") as stream:
        for raw_line in stream:
            parts = raw_line.rstrip("\r\n").split("\t", 1)
            if len(parts) == 2:
                rows[parts[0]] = parts[1].strip()
    return rows


def main() -> int:
    passages = load_passages()
    references = [entry.get("reference", "") for entry in passages]

    assert len(passages) == 100, f"expected 100 passages, found {len(passages)}"
    assert len(set(references)) == 100, "passage references must be unique"
    assert all(entry.get("text") for entry in passages), "every passage needs text"
    assert all(set(entry) == {"reference", "text"} for entry in passages), "unexpected passage fields"

    if len(sys.argv) > 1:
        official = load_bsb(pathlib.Path(sys.argv[1]))
        missing = [reference for reference in references if reference not in official]
        mismatched = [
            reference
            for reference, entry in zip(references, passages)
            if reference in official and official[reference] != entry["text"]
        ]
        assert not missing, f"references missing from official source: {missing}"
        assert not mismatched, f"text differs from official source: {mismatched}"

    print(f"Validated {len(passages)} unique BSB passages")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
