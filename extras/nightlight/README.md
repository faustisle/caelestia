# caelestia-nightlight

Small Wayland helper that applies the Hyprland CTM
(`hyprland-ctm-control-v1`) used by the night-light feature. It is spawned by
`NightLight.qml` and takes commands on stdin:

```text
temperature 4000
identity
quit
```

`identity` restores the neutral matrix. The helper also restores it on
SIGTERM/SIGINT and when the parent process exits.

## Build

The helper is built as part of the normal Caelestia CMake build:

```sh
cmake --build build -j2
```

It is installed as `caelestia-nightlight` in the normal binary directory.
Running the shell from a checkout also finds `build/lib/caelestia-nightlight`
automatically. Set `CAELESTIA_NIGHTLIGHT_BIN` to override the path.

## Protocol

The bundled `protocols/hyprland-ctm-control-v1.xml` is generated with
`wayland-scanner`; it is only needed at build time. Hyprland exposes the same
CTM manager used by `hyprsunset`, so no separate daemon is required.
