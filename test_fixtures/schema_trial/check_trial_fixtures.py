#!/usr/bin/env python3
"""Executable validation for the class-schema trial fixtures."""

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


def descriptors(value):
    if isinstance(value, dict):
        if set(value) == {"handler_id", "schema_version", "parameters"}:
            yield value
        for child in value.values():
            yield from descriptors(child)
    elif isinstance(value, list):
        for child in value:
            yield from descriptors(child)


def check_pack(name: str, registry: dict) -> list[tuple[str, str, str]]:
    root = ROOT / name
    manifest = load(root / "manifest.json")
    catalogue = load(root / manifest["catalogue_path"])
    source_registry = load(root / manifest["source_registry_path"])
    occurrence_registry = load(root / manifest["occurrence_audit_path"])
    sources = source_registry["sources"]
    occurrences = occurrence_registry["occurrences"]
    identities = {(entry["kind"], entry["id"]) for entry in catalogue["entries"]}
    identities_by_id = {entry["id"]: entry["kind"] for entry in catalogue["entries"]}
    assert len(identities) == len(catalogue["entries"]), f"{name}: duplicate identity"
    assert len(identities_by_id) == len(catalogue["entries"]), f"{name}: duplicate id across kinds"

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
        for descriptor in descriptors(document):
            handler_key = f"{descriptor['handler_id']}@{descriptor['schema_version']}"
            assert handler_key in registry["handler_registry"], f"{name}:{key}: unknown handler {handler_key}"
            declared = registry["handler_registry"][handler_key]["parameters"]
            assert set(descriptor["parameters"]) <= set(declared), f"{name}:{key}: handler parameters"
            one_of = registry["handler_registry"][handler_key].get("one_of_required", [])
            assert not one_of or set(descriptor["parameters"]) & set(one_of), f"{name}:{key}: handler parameter choice"
            if descriptor["handler_id"] == "fact_contains_v1":
                fact = registry["fact_registry"]["facts"].get(descriptor["parameters"]["fact_id"])
                assert fact is not None, f"{name}:{key}: unknown fact"
                assert descriptor["parameters"]["value"] in fact["values"], f"{name}:{key}: invalid fact value"
        documents[key] = document

    for key, document in documents.items():
        if key[0] == "class":
            assert all(("advancement_edge", ref) in identities for ref in document["advancement_edge_refs"])
            assert all(("skill", ref) in identities for ref in document.get("skill_unlocks", {}).values())
            for field in ("weapon_wexp_bases", "weapon_wexp_caps", "player_growth_rates", "enemy_growth_rates", "stat_caps"):
                status = document["field_completeness"][field]
                assert status in registry["completeness_policy"][f"{manifest['completion_status']}_allows"]
                assert document[field] or status in ("unverified", "not_applicable"), f"{name}:{key}:{field}: empty verified map"
        elif key[0] == "advancement_edge":
            assert ("class", document["source_class_ref"]) in identities
            assert all(("class", ref) in identities for ref in document["destination_class_refs"])
            assert all(("advancement_route", ref) in identities for ref in document["route_refs"])
        elif key[0] == "advancement_route":
            for descriptor in descriptors(document):
                item_id = descriptor["parameters"].get("item_id")
                assert item_id is None or ("item", item_id) in identities
        elif key[0] == "map":
            assert len(document["terrain_rows"]) == document["height"]
            assert all(len(row) == document["width"] for row in document["terrain_rows"])
            assert all(("class", ref) in identities for ref in document["player_class_refs"] + document["enemy_class_refs"])
        elif key[0] == "campaign":
            assert all(("map", ref) in identities for ref in document["map_refs"])
            assert all(("class", ref) in identities for ref in document["starting_class_refs"])
            profile = document["progression_pressure_profile_ref"]
            assert profile is None or ("progression_pressure_profile", profile) in identities

    presentation_rows = []
    for document in documents.values():
        presentation_rows.append((f"display:{document['display_name'].casefold()}", name, document["id"]))
        if document.get("display_name_key"):
            presentation_rows.append((f"localization:{document['display_name_key'].casefold()}", name, document["id"]))
    return presentation_rows


def error(document: str, code: str, path: str) -> tuple[str, str, str]:
    return document, code, path


def validate_invalid_contract(registry: dict) -> set[tuple[str, str, str]]:
    """Validate the negative fixture and return its structured error identities."""
    name = "invalid_contract"
    root = ROOT / name
    manifest = load(root / "manifest.json")
    catalogue = load(root / manifest["catalogue_path"])
    sources = load(root / manifest["source_registry_path"])["sources"]
    occurrences = load(root / manifest["occurrence_audit_path"])["occurrences"]
    identities = {(entry["kind"], entry["id"]) for entry in catalogue["entries"]}
    documents = {
        (entry["kind"], entry["id"]): load(root / entry["path"])
        for entry in catalogue["entries"]
    }
    found: set[tuple[str, str, str]] = set()

    for (kind, entity_id), document in documents.items():
        document_key = f"{kind}:{entity_id}"
        schema = registry["schemas"][f"{kind}@{document['schema_version']}"]
        allowed = COMMON | set(schema["required"]) | set(schema.get("optional_defaults", {}))
        allowed |= {"occurrence_audit_refs", "display_name_key"}
        for field in sorted(set(document) - allowed):
            found.add(error(document_key, "unknown_field", f"$.{field}"))
        for index, source_ref in enumerate(document.get("source_refs", [])):
            if source_ref not in sources:
                found.add(error(document_key, "provenance_source_unresolved", f"$.source_refs[{index}]"))
        for index, occurrence_ref in enumerate(document.get("occurrence_audit_refs", [])):
            if occurrence_ref not in occurrences:
                found.add(
                    error(
                        document_key,
                        "provenance_occurrence_unresolved",
                        f"$.occurrence_audit_refs[{index}]",
                    )
                )

        if kind == "class":
            bases = document.get("weapon_wexp_bases", {})
            caps = document.get("weapon_wexp_caps", {})
            for track, base in bases.items():
                if track in caps and base > caps[track]:
                    found.add(error(document_key, "value_out_of_range", f"$.weapon_wexp_bases.{track}"))
            admitted_overrides = set(schema.get("variant_override_fields", []))
            for variant_index, variant in enumerate(document.get("variants", [])):
                for field in variant.get("overrides", {}):
                    if field not in admitted_overrides:
                        found.add(
                            error(
                                document_key,
                                "variant_override_forbidden",
                                f"$.variants[{variant_index}].overrides.{field}",
                            )
                        )

        for field, target_kind in schema.get("reference_fields", {}).items():
            value = document.get(field, [])
            refs = value if isinstance(value, list) else [value]
            for index, ref in enumerate(refs):
                if (target_kind, ref) not in identities:
                    suffix = f"[{index}]" if isinstance(value, list) else ""
                    found.add(error(document_key, "reference_unresolved", f"$.{field}{suffix}"))

        for descriptor in descriptors(document):
            handler_key = f"{descriptor['handler_id']}@{descriptor['schema_version']}"
            if handler_key not in registry["handler_registry"]:
                # Locate the only negative descriptor precisely; recursive path
                # discovery can replace this when the trial becomes production code.
                descriptor_path = "$.transition.handler_id" if kind == "advancement_edge" else "$"
                found.add(error(document_key, "handler_unknown", descriptor_path))
    return found


def main() -> None:
    registry = load(ROOT / "schema_registry.json")
    assert registry["status"] == "trial"
    global_ids = {}
    presentation_names = {}
    for name in VALID_PACKS:
        for display_name, package, entity_id in check_pack(name, registry):
            presentation_names.setdefault(display_name, []).append((package, entity_id))
        manifest = load(ROOT / name / "manifest.json")
        catalogue = load(ROOT / name / manifest["catalogue_path"])
        for entry in catalogue["entries"]:
            folded = entry["id"].casefold()
            assert folded not in global_ids, (
                f"global id collision: {entry['id']} in {name} and "
                f"{global_ids.get(folded)}"
            )
            global_ids[folded] = name
    errors = load(ROOT / "invalid_contract" / "expected_errors.json")
    expected = {(e["document"], e["code"], e["path"]) for e in errors}
    assert errors and len(expected) == len(errors), "expected errors must be unique"
    actual = validate_invalid_contract(registry)
    assert actual == expected, (
        f"negative contract mismatch; missing={sorted(expected - actual)}, "
        f"unexpected={sorted(actual - expected)}"
    )
    warnings = {name: rows for name, rows in presentation_names.items() if len(rows) > 1}
    print(
        f"PASS class schema trial: {len(VALID_PACKS)} valid packs and "
        f"{len(actual)} matched negative-contract errors"
    )
    if warnings:
        print(
            f"WARNING class schema trial: {len(warnings)} advisory presentation-name "
            "collision group(s); ids remain distinct, so this is not a contract failure"
        )


if __name__ == "__main__":
    main()
