#!/usr/bin/env python3
"""Structural preflight for class-schema trial fixtures.

This intentionally checks fixture integrity, not the future Godot validator's full
behavior. The implementation suite must consume the same packs and expected errors.
"""

import json
from pathlib import Path


ROOT = Path(__file__).parent / "trial_v1"
VALID_PACKS = (
    "minimal_fixed",
    "branching_variant",
    "fed20_sample",
    "awakening_sample",
    "fe7_sample",
)
COMMON = {"kind", "schema_version", "id", "display_name", "source_refs"}


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def check_pack(name: str) -> None:
    root = ROOT / name
    manifest = load(root / "manifest.json")
    catalogue = load(root / manifest["catalogue_path"])
    source_registry = load(root / manifest["source_registry_path"])
    occurrence_registry = load(root / manifest["occurrence_audit_path"])
    sources = source_registry["sources"]
    occurrences = occurrence_registry["occurrences"]
    identities = {(entry["kind"], entry["id"]) for entry in catalogue["entries"]}
    assert len(identities) == len(catalogue["entries"]), f"{name}: duplicate identity"

    documents = {}
    for entry in catalogue["entries"]:
        document = load(root / entry["path"])
        key = (entry["kind"], entry["id"])
        assert COMMON <= document.keys(), f"{name}:{key}: common envelope"
        assert (document["kind"], document["id"]) == key, f"{name}:{key}: identity mismatch"
        assert document["schema_version"] == entry["schema_version"] == 1
        assert document["source_refs"], f"{name}:{key}: empty source_refs"
        assert all(ref in sources for ref in document["source_refs"]), f"{name}:{key}: source"
        assert all(ref in occurrences for ref in document.get("occurrence_audit_refs", []))
        documents[key] = document

    for key, document in documents.items():
        if key[0] == "class":
            assert all(("advancement_edge", ref) in identities for ref in document["advancement_edge_refs"])
        elif key[0] == "advancement_edge":
            assert ("class", document["source_class_ref"]) in identities
            assert all(("class", ref) in identities for ref in document["destination_class_refs"])
            assert all(("advancement_route", ref) in identities for ref in document["route_refs"])


def main() -> None:
    registry = load(ROOT / "schema_registry.json")
    assert registry["status"] == "trial"
    for name in VALID_PACKS:
        check_pack(name)
    errors = load(ROOT / "invalid_contract" / "expected_errors.json")
    assert errors and len({(e["document"], e["code"], e["path"]) for e in errors}) == len(errors)
    print(f"class schema trial fixtures: {len(VALID_PACKS)} valid packs and {len(errors)} expected errors OK")


if __name__ == "__main__":
    main()
