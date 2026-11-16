#!/usr/bin/env python3
"""Generate, save and apply Caelestia colour schemes.

This is a first-draft companion for the Nexus scheme creator. Custom schemes are
stored by the shell and applied through the CLI so that app templates are
updated as well. The CLI's state file is written with a valid built-in identity
so later CLI operations keep working.
"""

import argparse
import json
import os
import sys
import uuid
from pathlib import Path

VARIANTS = [
    "tonalspot",
    "vibrant",
    "expressive",
    "fidelity",
    "fruitsalad",
    "monochrome",
    "neutral",
    "rainbow",
    "content",
]


def caelestia_state(*parts: str) -> Path:
    base = Path(os.getenv("XDG_STATE_HOME", Path.home() / ".local/state")) / "caelestia"
    return base.joinpath(*parts)


PRESETS = caelestia_state("custom-schemes.json")
SCHEME = caelestia_state("scheme.json")


def load_presets() -> list[dict]:
    try:
        data = json.loads(PRESETS.read_text())
        return data if isinstance(data, list) else []
    except (OSError, json.JSONDecodeError):
        return []


def save_presets(presets: list[dict]) -> None:
    PRESETS.parent.mkdir(parents=True, exist_ok=True)
    PRESETS.write_text(json.dumps(presets, indent=4) + "\n")


def normalise_seed(seed: str) -> str:
    seed = seed.strip().lower().removeprefix("#")
    if len(seed) != 6 or any(c not in "0123456789abcdef" for c in seed):
        raise ValueError("Seed must be a six digit hex colour")
    return seed


def generate(seed: str, mode: str, variant: str) -> dict[str, str]:
    if mode not in ("dark", "light"):
        raise ValueError(f"Invalid mode: {mode}")
    if variant not in VARIANTS:
        raise ValueError(f"Invalid variant: {variant}")

    from types import SimpleNamespace

    from caelestia.utils.material.generator import gen_scheme, hex_to_hct

    scheme = SimpleNamespace(mode=mode, variant=variant, flavour="default")
    return gen_scheme(scheme, hex_to_hct(seed))


def apply_preset(preset: dict) -> None:
    from caelestia.utils.paths import atomic_dump
    from caelestia.utils.theme import apply_colours

    # Keep the CLI's identity valid so its other commands do not break. The
    # custom id/name lets the shell show and select the preset.
    atomic_dump(
        SCHEME,
        {
            "name": "caelestia",
            "flavour": "default",
            "mode": preset["mode"],
            "variant": preset["variant"],
            "colours": preset["colours"],
            "customId": preset["id"],
            "customName": preset["name"],
        },
    )
    apply_colours(preset["colours"], preset["mode"])


def find_preset(presets: list[dict], preset_id: str) -> dict:
    for preset in presets:
        if preset.get("id") == preset_id:
            return preset
    raise ValueError(f"Unknown scheme id: {preset_id}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    preview = sub.add_parser("preview", help="generate colours without saving them")
    preview.add_argument("--seed", required=True)
    preview.add_argument("--mode", required=True, choices=("dark", "light"))
    preview.add_argument("--variant", required=True, choices=VARIANTS)

    create = sub.add_parser("create", help="save a custom scheme")
    create.add_argument("--name", required=True)
    create.add_argument("--id")
    create.add_argument("--seed", required=True)
    create.add_argument("--mode", required=True, choices=("dark", "light"))
    create.add_argument("--variant", required=True, choices=VARIANTS)
    create.add_argument("--apply", action="store_true")

    apply_parser = sub.add_parser("apply", help="apply a saved custom scheme")
    apply_parser.add_argument("--id", required=True)

    delete_parser = sub.add_parser("delete", help="delete a saved custom scheme")
    delete_parser.add_argument("--id", required=True)

    args = parser.parse_args()

    if args.command == "preview":
        print(json.dumps({"colours": generate(normalise_seed(args.seed), args.mode, args.variant)}))
        return 0

    if args.command == "create":
        name = args.name.strip()
        if not name:
            raise ValueError("Name cannot be empty")

        presets = load_presets()
        if args.id:
            preset = next((p for p in presets if p.get("id") == args.id), None)
            if preset is None:
                raise ValueError(f"Unknown scheme id: {args.id}")
        else:
            preset = next((p for p in presets if p.get("name", "").lower() == name.lower()), None)
        if preset is None:
            preset = {"id": uuid.uuid4().hex, "name": name}
            presets.append(preset)

        preset.update(
            {
                "seed": f"#{normalise_seed(args.seed)}",
                "mode": args.mode,
                "variant": args.variant,
                "colours": generate(normalise_seed(args.seed), args.mode, args.variant),
            }
        )
        save_presets(presets)

        if args.apply:
            apply_preset(preset)

        print(json.dumps({"id": preset["id"], "applied": args.apply}))
        return 0

    if args.command == "delete":
        presets = load_presets()
        find_preset(presets, args.id)
        save_presets([p for p in presets if p.get("id") != args.id])

        # If the active scheme was deleted, fall back to the built-in Caelestia
        # palette so the CLI state and the visible scheme stay consistent.
        try:
            current = json.loads(SCHEME.read_text())
        except (OSError, json.JSONDecodeError):
            current = None

        if current and current.get("customId") == args.id:
            from caelestia.utils.paths import atomic_dump, scheme_data_dir
            from caelestia.utils.scheme import read_colours_from_file
            from caelestia.utils.theme import apply_colours

            mode = current.get("mode", "dark")
            colours = read_colours_from_file(scheme_data_dir / "caelestia" / "default" / f"{mode}.txt")
            atomic_dump(
                SCHEME,
                {
                    "name": "caelestia",
                    "flavour": "default",
                    "mode": mode,
                    "variant": current.get("variant", "tonalspot"),
                    "colours": colours,
                },
            )
            apply_colours(colours, mode)

        print(json.dumps({"id": args.id, "deleted": True}))
        return 0

    presets = load_presets()
    preset = find_preset(presets, args.id)
    apply_preset(preset)
    print(json.dumps({"id": preset["id"], "applied": True}))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        print(str(e), file=sys.stderr)
        raise SystemExit(1)
