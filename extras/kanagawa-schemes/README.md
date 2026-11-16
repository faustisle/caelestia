# Kanagawa schemes

Static Kanagawa palettes for Caelestia:

- `wave` — dark, medium contrast
- `dragon` — dark, higher contrast
- `lotus` — light

They are already installed in the local CLI package on this machine, so the
Nexus Colours page and `caelestia scheme …` list them directly.

## Reinstalling after a CLI update

The CLI stores schemes inside its Python package, which is replaced when the
package updates. Copy the templates back with:

```sh
sudo cp -r extras/kanagawa-schemes/kanagawa \
  "$(python3 -c 'import pathlib, caelestia; print(pathlib.Path(caelestia.__file__).parent / "data/schemes")')/"
```

Then verify and apply:

```sh
caelestia scheme list -n | grep kanagawa
caelestia scheme set -n kanagawa -f wave -m dark
```

Flavours `wave` and `dragon` only have a dark mode; `lotus` is light only.
