#!/usr/bin/env python3
"""Generate a Caelestia-themed icon theme from a source icon theme.

The source theme is expected to be a folder overlay such as the Nordic folder
icons. Every hard-coded colour in its SVGs is replaced with a role from the
current Caelestia scheme, and the generated theme inherits a full icon theme
(Papirus by default) for anything it does not provide itself.

This is deliberately a generator rather than a live theme: icon themes are
static SVG trees, so the result has to be rewritten when the scheme changes.

Wire it into the CLI so it runs on every scheme change, for example in
``~/.config/caelestia/cli.json``::

    {
        "theme": {
            "iconTheme": "caelestia-material",
            "iconThemeLight": "caelestia-material",
            "iconThemeDark": "caelestia-material",
            "postHook": "python3 /path/to/generate-icon-theme.py"
        }
    }
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

STATE_DIR = Path(os.getenv("XDG_STATE_HOME", Path.home() / ".local/state")) / "caelestia"
DATA_DIR = Path(os.getenv("XDG_DATA_HOME", Path.home() / ".local/share"))
DEFAULT_SCHEME = STATE_DIR / "scheme.json"
DEFAULT_OUTPUT = DATA_DIR / "icons/caelestia-material"

# Source colours use the Nord/Numix palette. Each one is mapped to the closest
# Material role so folders, accents and shadows all follow the scheme.
ROLE_MAP = {
    "aaaaaa": "onSurfaceVariant",  # generic foreground
    "727272": "onSurfaceVariant",
    "5294e2": "primary",  # highlight/accent
    "66bb6a": "primary",
    "637993": "secondaryContainer",  # folder back
    "708ba7": "primaryContainer",  # folder front
    "2e3440": "onPrimaryContainer",  # folder glyph
    "ffffff": "onPrimaryContainer",
    "666666": "outline",
    "e4e4e4": "onSurface",
    "81a1c1": "secondary",
    "13b1d5": "tertiary",
    "ffb86c": "tertiary",
    "f7aa94": "primary",
    "f07cac": "secondary",
    "ed72c7": "tertiary",
    "7b7b7b": "outlineVariant",
    "1e1f29": "surface",
    "000000": "shadow",
    "fdb99b": "tertiaryContainer",
    "cf8bf3": "secondary",
    "a770ef": "primary",
    "698989": "secondaryContainer",
    "4d646f": "surfaceContainerHighest",
}

# Some source icons use rgb() with baked-in gradients instead of hex colours.
RGB_MAP = {
    (252, 203, 144): "primary",
    (213, 126, 235): "tertiary",
    (255, 255, 255): "onPrimaryContainer",
    (240, 135, 5): "primary",
    (77, 100, 111): "primaryContainer",
}

# App logos keep their brand colours; generic app icons can follow the scheme.
BRAND_ICONS = {"firefox.svg"}

ROLE_FALLBACKS = {
    "primary": "secondary",
    "secondary": "primary",
    "tertiary": "secondary",
    "surface": "background",
    "background": "surface",
    "onSurface": "text",
    "text": "onSurface",
    "onSurfaceVariant": "subtext1",
    "subtext1": "onSurfaceVariant",
    "primaryContainer": "surfaceContainerHigh",
    "secondaryContainer": "surfaceContainerHigh",
    "tertiaryContainer": "surfaceContainer",
    "surfaceContainerHighest": "surfaceVariant",
    "surfaceContainerHigh": "surfaceContainer",
    "surfaceContainer": "surface",
    "surfaceVariant": "surfaceContainerHighest",
    "outline": "onSurfaceVariant",
    "outlineVariant": "outline",
    "onPrimaryContainer": "onSurface",
    "shadow": "surface",
    "primaryFixedDim": "primaryContainer",
    "surfaceContainerLowest": "surface",
}

HEX_RE = re.compile(r"#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?")
RGB_RE = re.compile(r"rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*(?:,\s*([0-9.]+)\s*)?\)", re.IGNORECASE)

PREVIEW_ICONS = [
    ("Places/48/folder.svg", "Folder"),
    ("Places/48/folder-download.svg", "Downloads"),
    ("Places/48/folder-documents.svg", "Documents"),
    ("Places/48/folder-music.svg", "Music"),
    ("Places/48/folder-pictures.svg", "Pictures"),
    ("Places/48/folder-videos.svg", "Videos"),
    ("Places/48/folder-recent.svg", "Recent"),
    ("Places/48/folder-templates.svg", "Templates"),
    ("Places/48/folder-publicshare.svg", "Public"),
    ("Places/48/inode-directory.svg", "Directory"),
    ("apps/scalable/system-file-manager.svg", "Files"),
    ("apps/scalable/firefox.svg", "Firefox"),
]


def scheme_colours(scheme_path: Path) -> tuple[dict, dict[str, str]]:
    try:
        scheme = json.loads(scheme_path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        raise SystemExit(f"Unable to read scheme from {scheme_path}: {exc}") from exc

    colours = {name: value.lstrip("#") for name, value in scheme.get("colours", {}).items()}

    def get(role: str) -> str:
        seen = set()
        current = role
        while current not in seen:
            seen.add(current)
            if current in colours:
                return colours[current]
            current = ROLE_FALLBACKS.get(current, "")
            if not current:
                break

        return "000000"

    roles = {role: get(role) for role in set(ROLE_MAP.values()) | {"primaryFixedDim", "surfaceContainerLowest"}}
    return scheme, roles


def find_source(explicit: str | None) -> Path:
    if explicit:
        path = Path(explicit).expanduser()
        if not path.is_dir():
            raise SystemExit(f"Source icon theme not found: {path}")
        return path

    candidates = [
        Path.home() / ".icons/Nordic-bluish",
        Path.home() / ".icons/Nordic-darker",
        Path.home() / ".icons/Nordic-green",
        Path.home() / ".local/share/icons/Nordic-bluish",
        Path("/usr/share/icons/Nordic-bluish"),
    ]
    for candidate in candidates:
        if candidate.is_dir():
            return candidate

    raise SystemExit("Unable to find a Nordic folder theme. Pass --source explicitly.")


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))


def blend_hex(first: str, second: str, amount: float) -> str:
    first_rgb = hex_to_rgb(first)
    second_rgb = hex_to_rgb(second)
    return "".join(f"{round(a * (1 - amount) + b * amount):02x}" for a, b in zip(first_rgb, second_rgb))


def replace_colours(text: str, mapping: dict[str, str], roles: dict[str, str]) -> str:
    def substitute_hex(match: re.Match) -> str:
        colour = match.group(1).lower()
        return f"#{mapping.get(colour, colour)}{match.group(2) or ''}"

    def substitute_rgb(match: re.Match) -> str:
        rgb = tuple(int(match.group(index)) for index in (1, 2, 3))
        role = RGB_MAP.get(rgb)
        if role is None:
            return match.group(0)

        red, green, blue = hex_to_rgb(roles.get(role, "000000"))
        alpha = match.group(4)
        if alpha is None:
            return f"rgb({red},{green},{blue})"

        return f"rgba({red},{green},{blue},{alpha})"

    return RGB_RE.sub(substitute_rgb, HEX_RE.sub(substitute_hex, text))


def set_element_style(text: str, element_id: str, style: str) -> str:
    pattern = re.compile(r'(id="%s"\s+style=")([^"]*)(")' % re.escape(element_id))
    text, _count = pattern.subn(lambda match: match.group(1) + style + match.group(3), text)
    return text


def style_folder_48(text: str, roles: dict[str, str], mode: str) -> str:
    """Use the folder's existing inner-shadow layer as a subtle paper edge."""
    if not all(f'id="{element}"' in text for element in ("path2", "path4", "path6")):
        return text

    back = roles.get("secondaryContainer", "000000")
    front = roles.get("primaryContainer", "000000")
    paper = roles.get("surfaceContainerLowest", "ffffff") if mode == "light" else roles.get("primaryFixedDim", "ffffff")
    glyph = roles.get("onPrimaryContainer", "ffffff")

    if mode != "light":
        accent = roles.get("primary", "ffffff")
        back = blend_hex(back, accent, 0.25)
        front = blend_hex(front, accent, 0.30)

    text = set_element_style(text, "path2", f"fill:#{back};fill-opacity:1;stroke:none")
    text = set_element_style(text, "path4", f"fill:#{paper};fill-opacity:1;stroke:none")
    text = set_element_style(text, "path6", f"fill:#{front};fill-opacity:1;stroke:none")
    text = set_element_style(text, "path8", f"fill:#{glyph};fill-opacity:1;stroke:none;opacity:0.4")
    return text


def generate_theme(
    source: Path,
    output: Path,
    name: str,
    inherit: str,
    mapping: dict[str, str],
    roles: dict[str, str],
    mode: str,
) -> int:
    output = output.expanduser()
    output.parent.mkdir(parents=True, exist_ok=True)

    temp = Path(tempfile.mkdtemp(prefix=f".{output.name}-", dir=output.parent))
    written = 0
    skipped = 0

    try:
        for root, _dirs, files in os.walk(source):
            rel = Path(root).relative_to(source)
            (temp / rel).mkdir(parents=True, exist_ok=True)
            is_app = bool(rel.parts) and rel.parts[0] == "apps"

            for file in files:
                src = Path(root) / file
                dst = temp / rel / file

                try:
                    if file.endswith(".svg") and not (is_app and file in BRAND_ICONS):
                        text = src.read_text(encoding="utf-8", errors="surrogateescape")
                        text = replace_colours(text, mapping, roles)
                        if rel.parts[:2] == ("Places", "48"):
                            text = style_folder_48(text, roles, mode)
                        dst.write_text(text, encoding="utf-8", errors="surrogateescape")
                        written += 1
                    elif file != "icon-theme.cache":
                        shutil.copy2(src, dst)
                except FileNotFoundError:
                    skipped += 1

        index = source / "index.theme"
        if index.is_file():
            content = index.read_text(encoding="utf-8", errors="surrogateescape")
            content = re.sub(r"^Name=.*$", f"Name={name}", content, count=1, flags=re.MULTILINE)
            content = re.sub(r"^Comment=.*$", f"Comment=Themed by Caelestia from {source.name}.", content, count=1, flags=re.MULTILINE)
            content = re.sub(r"^Inherits=.*$", f"Inherits={inherit}", content, count=1, flags=re.MULTILINE)
            (temp / "index.theme").write_text(content, encoding="utf-8", errors="surrogateescape")

        old = output.with_name(f".{output.name}-old")
        if old.exists():
            shutil.rmtree(old)
        if output.exists():
            output.rename(old)

        temp.rename(output)

        if old.exists():
            shutil.rmtree(old)

        for path in (output, *output.rglob("*")):
            if path.is_dir():
                path.chmod(0o755)
            elif path.is_file():
                path.chmod(0o644)

        subprocess.run(
            ["gtk-update-icon-cache", "-f", "-t", str(output)],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    finally:
        if temp.exists():
            shutil.rmtree(temp, ignore_errors=True)

    if skipped:
        print(f"Skipped {skipped} broken entries.", file=sys.stderr)
    return written


def render_preview(theme: Path, scheme: dict, roles: dict[str, str], destination: Path, name: str) -> None:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        raise SystemExit("Pillow is required to render a preview image.")

    destination = destination.expanduser()
    destination.parent.mkdir(parents=True, exist_ok=True)

    def colour(role: str, fallback: str = "surface") -> str:
        return f"#{roles.get(role, roles.get(fallback, '000000'))}"

    icons = [(theme / path, label) for path, label in PREVIEW_ICONS if (theme / path).is_file()]
    if not icons:
        raise SystemExit("No suitable icons found for the preview.")

    scale = 2
    margin = 32
    columns = 6
    rows = (len(icons) + columns - 1) // columns
    cell_w = 176
    cell_h = 168
    header_h = 116
    width = margin * 2 + columns * cell_w
    height = header_h + margin + rows * cell_h + margin

    background = colour("surface")
    card = colour("surfaceContainerLow")
    title_colour = colour("onSurface")
    label_colour = colour("onSurfaceVariant")

    image = Image.new("RGB", (width * scale, height * scale), background)
    draw = ImageDraw.Draw(image)
    font_path = "/usr/share/fonts/noto/NotoSans-Regular.ttf"
    bold_path = "/usr/share/fonts/noto/NotoSans-Bold.ttf"
    title_font = ImageFont.truetype(bold_path, 28 * scale)
    subtitle_font = ImageFont.truetype(font_path, 14 * scale)
    label_font = ImageFont.truetype(font_path, 13 * scale)

    draw.text((margin * scale, 26 * scale), name, font=title_font, fill=title_colour)
    subtitle = f"{scheme.get('mode', 'dark')} · {scheme.get('variant', 'tonalspot')} · {scheme.get('name', 'scheme')}"
    draw.text((margin * scale, 64 * scale), subtitle, font=subtitle_font, fill=label_colour)

    swatches = ["primary", "secondary", "tertiary", "error", "surfaceContainerHighest", "outline"]
    x = margin * scale
    for role in swatches:
        draw.rounded_rectangle([x, 90 * scale, x + 26 * scale, 104 * scale], radius=4 * scale, fill=colour(role))
        x += 34 * scale

    with tempfile.TemporaryDirectory(prefix="caelestia-preview-") as temp_dir:
        for index, (icon, label) in enumerate(icons):
            column = index % columns
            row = index // columns
            x = (margin + column * cell_w) * scale
            y = (header_h + margin + row * cell_h) * scale
            draw.rounded_rectangle([x, y, x + (cell_w - 16) * scale, y + (cell_h - 16) * scale], radius=14 * scale, fill=card)

            rendered = Path(temp_dir) / f"{index}.png"
            result = subprocess.run(
                ["rsvg-convert", "-w", str(112 * scale), "-h", str(112 * scale), "-o", str(rendered), str(icon)],
                check=False,
                capture_output=True,
            )
            if result.returncode != 0:
                continue

            icon_image = Image.open(rendered).convert("RGBA")
            icon_left = x + ((cell_w - 16) * scale - icon_image.width) // 2
            icon_top = y + 8 * scale
            image.paste(icon_image, (icon_left, icon_top), icon_image)
            draw.text(
                (x + (cell_w - 16) * scale // 2, y + (cell_h - 38) * scale),
                label,
                font=label_font,
                fill=label_colour,
                anchor="ma",
            )

    image.resize((width, height), Image.Resampling.LANCZOS).save(destination)
    print(f"Preview written to {destination}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scheme", type=Path, default=DEFAULT_SCHEME, help="Caelestia scheme.json")
    parser.add_argument("--source", help="Source folder icon theme")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="Output icon theme directory")
    parser.add_argument("--name", default="Caelestia Material", help="Generated theme display name")
    parser.add_argument("--inherit", default="Papirus-Dark", help="Fallback icon theme")
    parser.add_argument("--preview", type=Path, help="Write a PNG contact sheet")
    args = parser.parse_args()

    scheme, roles = scheme_colours(args.scheme)
    source = find_source(args.source)
    mapping = {colour: roles[role] for colour, role in ROLE_MAP.items()}
    written = generate_theme(source, args.output, args.name, args.inherit, mapping, roles, scheme.get("mode", "dark"))

    print(f"Generated {args.output} from {source} ({written} SVGs).")
    if args.preview:
        render_preview(args.output.expanduser(), scheme, roles, args.preview, args.name)

    return 0


if __name__ == "__main__":
    sys.exit(main())
