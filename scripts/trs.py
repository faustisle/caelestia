#!/usr/bin/env python3

import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TR_DIR = ROOT / "plugin/src/Caelestia/I18n/trs"
POT_FILE = TR_DIR / "raw.pot"

XGETTEXT_ARGS = [
    "-o",
    str(POT_FILE),
    "--join-existing",
    "--from-code=UTF-8",
    "--no-wrap",
    "--add-location=file",
    "--add-comments=TRANSLATORS:",
    "--package-name=caelestia-shell",
    "-k",
    "-ktr:1",
    "-ktrCtx:2c,1",
    "-ktrMarked:1",
    "-ktrN:1,2",
    "-ktrCtxN:4c,1,2",
    "-kmark:1",
    "-kmarkCtx:2c,1",
    "-kmarkN:1,2",
    "-kmarkCtxN:4c,1,2",
]


def usage() -> None:
    print(f"Usage: {Path(sys.argv[0]).name} raw|compile|test|<ll_CC>", file=sys.stderr)


def source_files(pattern: str) -> list[str]:
    files = []
    for path in ROOT.rglob(pattern):
        rel = path.relative_to(ROOT)
        if "build" in rel.parts:
            continue
        files.append(str(rel))
    return sorted(files)


def gen(language: str, files: list[str]) -> None:
    if not files:
        return
    subprocess.run(["xgettext", "-L", language, *XGETTEXT_ARGS, *files], check=True)


def process_pot() -> None:
    blocks = POT_FILE.read_text(encoding="utf-8").split("\n\n")
    result = []

    for block in blocks:
        lines = [line for line in block.splitlines() if line.strip() != "#, javascript-format"]
        lines = [line.replace(", javascript-format", "") for line in lines]

        body = "\n".join(lines)
        formats = []
        if re.search(r"%L?[1-9]", body):
            formats.append("qt-format")
        if re.search(r"%L?n", body):
            formats.append("qt-plural-format")

        if formats and not re.search(r"^#,.*qt-format", body, re.MULTILINE):
            format_line = f"#, {', '.join(formats)},"
            for index, line in enumerate(lines):
                if line.startswith(("msgctxt ", "msgid ")):
                    lines.insert(index, format_line)
                    break
            else:
                lines.insert(0, format_line)

        result.append("\n".join(lines))

    POT_FILE.write_text("\n\n".join(result), encoding="utf-8")


def gen_trs() -> None:
    TR_DIR.mkdir(parents=True, exist_ok=True)
    POT_FILE.write_text("", encoding="utf-8")

    gen("JavaScript", source_files("*.qml"))
    gen("C++", source_files("*.cpp") + source_files("*.hpp"))

    process_pot()


def compile_po(po: Path, output: str) -> None:
    subprocess.run(["msgfmt", "--check-format", "-o", output, str(po)], check=True)


def run_test(output: str) -> None:
    if not POT_FILE.exists():
        gen_trs()

    with tempfile.TemporaryDirectory() as tmp:
        test_po = Path(tmp) / "test.po"
        subprocess.run(
            [
                "msginit",
                "--locale=en_US",
                f"--input={POT_FILE}",
                f"--output={test_po}",
                "--no-translator",
            ],
            check=True,
            stderr=subprocess.DEVNULL,
        )

        text = test_po.read_text(encoding="utf-8")
        text = re.sub(r'^msgstr(\[\d+\])? "(.*)"$', r'msgstr\1 "[[ \2 ]]"', text, flags=re.MULTILINE)
        test_po.write_text(text, encoding="utf-8")

        compile_po(test_po, output)


def main() -> int:
    if len(sys.argv) < 2:
        usage()
        return 1

    command = sys.argv[1]

    if command == "raw":
        gen_trs()
        return 0

    if command == "compile":
        if len(sys.argv) < 4:
            print(f"Usage: {Path(sys.argv[0]).name} compile <ll_CC> <out_file>", file=sys.stderr)
            return 1
        compile_po(TR_DIR / f"{sys.argv[2]}.po", sys.argv[3])
        return 0

    if not POT_FILE.exists():
        gen_trs()

    if command == "test":
        if len(sys.argv) < 3:
            print(f"Usage: {Path(sys.argv[0]).name} test <out_file>", file=sys.stderr)
            return 1
        run_test(sys.argv[2])
        return 0

    subprocess.run(
        [
            "msginit",
            f"--locale={command}",
            f"--input={POT_FILE}",
            f"--output={TR_DIR / f'{command}.po'}",
        ],
        check=True,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
