<h1 align=center>caelestia-shell</h1>

> a personal fork that removes things I didn't want and added things I did :)

This is a personal fork of [Caelestia](https://github.com/caelestia-dots/shell/).
It is not the upstream project, so some upstream documentation and packaging may
not match what is in this repository.

## What's new

A quick overview of the fork-specific changes. See the commit history for the
full set.

### Added

- **Night light** — schedule-based screen warming with a 15-minute fade,
  configurable temperature, a Nexus page, and a quick toggle.
- **Notification status icon** — notifications in history appear as a
  conditional bar icon with a hover popout. The old notifications sidebar was
  replaced by the quick-settings hover panel.
- **Panel positioning** — the bar can sit on the top, bottom, or left edge via
  `bar.position`.
- **Desktop icons** — show files and folders on the desktop, reorder them by
  dragging, drop files and folders onto the desktop, and choose single-click or
  double-click opening. Configure it under `background.desktopIcons`.
- **Desktop context menu** — new folder/file, sort by name, size, type, or
  modified, toggle desktop icons, and open Nexus settings pages directly.
  Files and folders also get open, rename, reveal, and confirmed-delete actions.
- **Caelestia Material icon theme** — generate a scheme-coloured folder icon
  theme from Nordic folder art, inheriting Papirus-Dark for app icons. It can
  regenerate automatically after scheme changes.
- **Scheme editor** — create, manage, and apply custom colour schemes from Nexus.
  Added Kanagawa schemes are bundled as well.
- **Extra Nexus pages** — Input (pointer and touchpad settings), Displays
  (monitor arrangement and modes), Storage (disk usage and cleanup), Colours,
  and a launcher logo picker.
- **System monitor** — performance popout, compact sysmon and tray for
  horizontal panels, high CPU/memory alerts, app-volume status and popout, plus
  calendar and notification popouts.
- **Launcher** — centred spotlight mode, optional screen dimming while open, and
  opening from the panel button.
- **Session menu** — horizontal layout, action labels, number badges, and
  keyboard shortcuts.
- **Sliders** — wavy fill animation and click-to-seek.
- **Lock screen** — rearranged clock, centred layout, and taskbar shortcuts that
  open the matching settings pages.

### Removed

- Weather, media playback, the cava visualiser, and the
  screen recorder.
- Dashboard and profile/face functionality.
- Per-device Bluetooth icons in the bar.

## Components

- Widgets: [Quickshell](https://quickshell.outfoxxed.me)
- Window manager: [Hyprland](https://hypr.land)
- CLI: [caelestia-cli](https://github.com/caelestia-dots/cli) (scheme, wallpaper,
  and IPC commands)

## Installation

This fork is not packaged. Build it manually from source. A setup script may be
added later.

### Dependencies

Runtime dependencies:

- [`caelestia-cli`](https://github.com/caelestia-dots/cli)
- [`quickshell`](https://git.outfoxxed.me/quickshell/quickshell) — the git
  version, not the latest tagged release
- `glibc`
- `gcc-libs`
- [`ddcutil`](https://github.com/rockowitz/ddcutil)
- [`brightnessctl`](https://github.com/Hummer12007/brightnessctl)
- [`networkmanager`](https://gitlab.freedesktop.org/NetworkManager/NetworkManager)
- [`lm_sensors`](https://github.com/lm-sensors/lm-sensors)
- [`libpipewire`](https://github.com/PipeWire/pipewire)
- [`power-profiles-daemon`](https://gitlab.freedesktop.org/upower/power-profiles-daemon)
- [`ttf-material-symbols-variable`](https://github.com/google/material-design-icons)
- [`ttf-rubik-vf`](https://github.com/googlefonts/rubik)
- [`ttf-cascadia-code-nerd`](https://github.com/ryanoasis/nerd-fonts)
- `qt6-base`
- `qt6-declarative`
- `qt6-imageformats`
- `qt6-multimedia`
- [`qt6-m3shapes-git`](https://github.com/soramanew/m3shapes)
- [`bash`](https://www.gnu.org/software/bash)
- `python` (used by the CLI and the icon theme generator)

Icon theme dependencies (optional):

- `papirus-icon-theme` (provides the Papirus-Dark fallback)
- `gtk-update-icon-cache` (usually provided by GTK)
- a [Nordic](https://github.com/EliverLara/Nordic) folder theme installed under `~/.icons` (for example,
  `Nordic-bluish`, `Nordic-darker`, or `Nordic-green`)

Build dependencies:

- [`cmake`](https://gitlab.kitware.com/cmake/cmake)
- [`ninja`](https://github.com/ninja-build/ninja)
- `qt6-shadertools`
- `wayland` (provides `wayland-scanner` for the night-light helper)
- `git`

> [!IMPORTANT]
> The commands below assume `$XDG_CONFIG_HOME` is set. If it is unset,
> substitute the path to your config folder (typically `~/.config`).

### Manual installation

Clone this fork and build it with CMake:

```sh
git clone https://github.com/faustisle/caelestia.git
cd caelestia

cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build
sudo cmake --install build
```

If you prefer to install into your config directory for easy local changes:

```sh
mkdir -p "$HOME/.config/quickshell/caelestia"
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ \
    -DINSTALL_QSCONFDIR="$HOME/.config/quickshell/caelestia"
cmake --build build
sudo cmake --install build
sudo chown -R "$USER" "$HOME/.config/quickshell/caelestia"
```

`INSTALL_LIBDIR`, `INSTALL_QMLDIR`, and `INSTALL_QSCONFDIR` control where the
libraries, QML plugin, and Quickshell config are installed. If you override
`INSTALL_LIBDIR`, set `CAELESTIA_LIB_DIR` to the same directory in your
environment.

### Running from the checkout

For development, point Quickshell at the checkout and the build output:

```sh
QML2_IMPORT_PATH="$PWD/build/qml" \
CAELESTIA_LIB_DIR="$PWD/build/lib" \
qs -p "$PWD" -n
```

If the shell is installed, start it with:

```sh
caelestia shell -d
```

## Usage

### Shortcuts and IPC

All actions are exposed as Hyprland global shortcuts. Bind them in your
Hyprland config, or call them through IPC:

```sh
caelestia shell -s          # list available IPC commands
caelestia shell wallpaper list
```

### Night light

Night light is configured under **Nexus → Night light**. It fades in over the
15 minutes before the start time and fades out over the 15 minutes after the
end time; both the schedule and transition length are configurable. There is
also a quick toggle in the utilities sidebar.

The colour transform is handled by the bundled `caelestia-nightlight` helper, so no
external `hyprsunset`/`gammastep` daemon is needed. IPC controls are available
under the `nightLight` target:

```sh
caelestia shell ipc call nightLight toggle
caelestia shell ipc call nightLight setTemperature 4000
```

### Wallpapers

Wallpapers are read from `~/Pictures/Wallpapers` by default. Change this with
`paths.wallpaperDir` in `~/.config/caelestia/shell.json`.

Set a wallpaper from the launcher with `>wallpaper`, or directly:

```sh
caelestia wallpaper -f <path_to_wallpaper>
```

### Image viewer

Images open in a floating viewer with the other images from the same directory.
Scroll to zoom, drag to pan, use the arrow keys to move through the directory,
`0` to fit, `1` for 100% zoom, double-click or `F11`/`F` to toggle fullscreen
and `Escape` to close. In fullscreen, images that reach the top of the screen
extend underneath a slightly tinted toolbar. Animated GIF and APNG files play,
and image files on the desktop also open in this viewer.

Open an image from a keybind, file manager or terminal:

```sh
caelestia shell imageViewer open <path_to_image>
```

To make it the default handler for images, point an XDG desktop entry at that
command:

```ini
[Desktop Entry]
Type=Application
Name=Caelestia Image Viewer
Exec=caelestia shell imageViewer open %f
MimeType=image/jpeg;image/png;image/webp;image/tiff;image/svg+xml;
NoDisplay=true
```

### Icon theme

The fork includes a generator for a `caelestia-material` icon theme. It recolours
the Nordic folder overlay to the current scheme and inherits Papirus-Dark for
everything else, so app logos keep their brand colours.

Generate or refresh the theme with:

```sh
python3 assets/generate-icon-theme.py
```

This writes `~/.local/share/icons/caelestia-material`. The generator picks the
first available Nordic folder theme from `~/.icons/Nordic-bluish`,
`Nordic-darker`, or `Nordic-green`.

To regenerate automatically whenever the scheme changes, add this to
`~/.config/caelestia/cli.json`:

```json
{
    "theme": {
        "iconTheme": "caelestia-material",
        "iconThemeLight": "caelestia-material",
        "iconThemeDark": "caelestia-material",
        "postHook": "python3 /path/to/caelestia/assets/generate-icon-theme.py"
    }
}
```

Then apply the icon theme through the CLI, for example:

```sh
caelestia scheme set -n dynamic
```

If your GTK apps read `~/.config/gtk-3.0/settings.ini` or
`~/.config/gtk-4.0/settings.ini` directly, set
`gtk-icon-theme-name=caelestia-material` there too. For Qt6CT, set
`icon_theme=caelestia-material` in `~/.config/qt6ct/qt6ct.conf`.

## Configuring

All configuration belongs in `~/.config/caelestia/shell.json`. The file is not
created by default; create it manually. Options you omit use their default
values.

### Global and per-monitor configuration

Per-monitor overrides live in `~/.config/caelestia/monitors/<monitor_name>/shell.json`.
List monitor names with:

```sh
hyprctl monitors -j | jq -r '.[].name'
```

Options in per-monitor files override the global config. Any option not present
inherits the global value.

For example, to hide the bar on `DP-1`:

**`~/.config/caelestia/monitors/DP-1/shell.json`**

```json
{
    "bar": {
        "persistent": false
    }
}
```

> [!NOTE]
> Not all options respect per-monitor overrides. Most notably, the following
> options are read only from the global config:
>
> <details><summary>Ignored options</summary>
>
> - `appearance`: `anim.*`, `transparency.*`
> - `bar.tray`: `hiddenIcons`, `iconSubs`
> - `bar.workspaces`: `ignoredTags`, `specialWorkspaceIcons`, `windowIcons`,
>   `workspaceIcons`
> - `general`: `apps.*`, `battery.*`, `idle.*`, `logo`
> - `launcher`: `actionPrefix`, `actions`, `enableDangerousActions`,
>   `favouriteApps`, `hiddenApps`, `specialPrefix`, `useFuzzy.*`, `vimKeybinds`
> - `lock`: `enableFprint`, `enableHowdy`, `maxFprintTries`, `maxHowdyTries`,
>   `triggerHowdyOnWake`
> - `nexus`: `networkRescanInterval`
> - `notifs`: `actionOnClick`, `defaultExpireTimeout`, `expire`, `fullscreen`,
>   `fullscreenExpireTimeout`
> - `paths`: `wallpaperDir`
> - `services`: `audioIncrement`, `brightnessIncrement`, `clockFormat`,
>   `dataUnits`, `gpuType`, `maxVolume`, `resourceUpdateInterval`,
>   `sensorUnits`, `smartScheme`
> - `utilities`: `gameMode.*`, `toasts.*`, `vpn.*`
>
> </details>

### Fork-specific options

- `bar.position` — `top`, `bottom`, or `left`.
- `background.desktopIcons` — `enabled`, `showLabels`, `showFiles`,
  `doubleClick`, `iconSize`, `position`, `sortBy`, and `order`.
- `launcher.spotlight` and `launcher.dim` — centred launcher mode and screen
  dimming.
- `bar.sysMonitor.performance` — choose the metrics shown in the performance
  popout.
- `bar.statusIcons` — includes the `appVolumes` status icon.

### Example configuration

> [!WARNING]
> The example configuration includes **ALL** configuration options in `shell.json`. It is
> **not** recommended to copy and paste this entire configuration into `shell.json`,
> as options or their default values may change across updates, resulting in a stale config.
>
> This is meant to serve as a reference of all the available options, and you should
> <ins>only add the ones you want to change</ins> to `shell.json`.

<details><summary>Example config</summary>

```json
{
    "enabled": true,
    "appearance": {
        "deformScale": 1,
        "rounding": {
            "scale": 1
        },
        "spacing": {
            "scale": 1
        },
        "padding": {
            "scale": 1
        },
        "font": {
            "scale": 1,
            "clock": "Rubik",
            "workspaces": "Rubik",
            "headline": {
                "family": "GoogleSansFlex",
                "large": {
                    "size": 32,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "medium": {
                    "size": 28,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "small": {
                    "size": 24,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                }
            },
            "title": {
                "family": "GoogleSansFlex",
                "large": {
                    "size": 22,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "medium": {
                    "size": 16,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "small": {
                    "size": 14,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                }
            },
            "body": {
                "family": "GoogleSansFlex",
                "large": {
                    "size": 16,
                    "weight": 400,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "medium": {
                    "size": 14,
                    "weight": 400,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "small": {
                    "size": 12,
                    "weight": 400,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                }
            },
            "label": {
                "family": "GoogleSansFlex",
                "large": {
                    "size": 14,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "medium": {
                    "size": 12,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "small": {
                    "size": 11,
                    "weight": 400,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                }
            },
            "mono": {
                "family": "CaskaydiaCove NF",
                "large": {
                    "size": 16,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                },
                "medium": {
                    "size": 14,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                },
                "small": {
                    "size": 12,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                }
            },
            "icon": {
                "family": "Material Symbols Rounded",
                "extraLarge": {
                    "size": 36,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                },
                "large": {
                    "size": 24,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                },
                "medium": {
                    "size": 18,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                },
                "small": {
                    "size": 15,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                }
            }
        },
        "anim": {
            "durations": {
                "scale": 1
            }
        },
        "transparency": {
            "enabled": false,
            "base": 0.85,
            "layers": 0.4
        }
    },
    "general": {
        "logo": "",
        "showOverFullscreen": false,
        "apps": {
            "terminal": ["foot"],
            "audio": ["pwvucontrol"],
            "playback": ["mpv"],
            "explorer": ["thunar"]
        },
        "idle": {
            "lockBeforeSleep": true,
            "inhibitWhenCharging": false,
            "timeouts": [
                {
                    "timeout": 180,
                    "idleAction": "lock",
                    "inhibitWhenCharging": false,
                    "respectInhibitors": true
                },
                {
                    "timeout": 300,
                    "idleAction": "dpms off",
                    "returnAction": "dpms on"
                },
                {
                    "timeout": 600,
                    "idleAction": ["suspendThenHibernate"]
                }
            ]
        },
        "battery": {
            "warnLevels": [
                {
                    "level": 20,
                    "title": "Low battery",
                    "message": "You might want to plug in a charger",
                    "icon": "battery_android_frame_2"
                },
                {
                    "level": 10,
                    "title": "Did you see the previous message?",
                    "message": "You should probably plug in a charger <b>now</b>",
                    "icon": "battery_android_frame_1"
                },
                {
                    "level": 5,
                    "title": "Critical battery level",
                    "message": "PLUG THE CHARGER RIGHT NOW!!",
                    "icon": "battery_android_alert",
                    "critical": true
                }
            ],
            "criticalLevel": 3
        }
    },
    "background": {
        "enabled": true,
        "wallpaperEnabled": true,
        "desktopClock": {
            "enabled": false,
            "scale": 1.0,
            "position": "bottom-right",
            "invertColors": false,
            "background": {
                "enabled": false,
                "opacity": 0.7,
                "blur": true
            },
            "shadow": {
                "enabled": true,
                "opacity": 0.7,
                "blur": 0.4
            }
        },
        "desktopIcons": {
            "enabled": true,
            "showLabels": true,
            "showFiles": true,
            "doubleClick": true,
            "iconSize": 48,
            "position": "top-right",
            "sortBy": "custom",
            "order": []
        }
    },
    "bar": {
        "position": "left",
        "persistent": true,
        "showOnHover": true,
        "dragThreshold": 20,
        "scrollActions": {
            "workspaces": true,
            "volume": true,
            "brightness": true
        },
        "popouts": {
            "tray": true,
            "statusIcons": true,
            "clock": true,
            "sysMonitor": true
        },
        "workspaces": {
            "shown": 5,
            "activeIndicator": true,
            "occupiedBg": false,
            "showUnoccupied": true,
            "perMonitor": true,
            "showWindows": true,
            "showWindowsOnSpecialWorkspaces": true,
            "maxWindowIcons": 5,
            "activeTrail": false,
            "displayType": "shapes",
            "specialDisplayType": "icons",
            "label": "  ",
            "occupiedLabel": "󰮯",
            "activeLabel": "󰮯",
            "capitalisation": "preserve",
            "workspaceIcons": [],
            "specialWorkspaceIcons": [
                {
                    "name": "special",
                    "icon": "star"
                },
                {
                    "name": "communication",
                    "icon": "forum"
                },
                {
                    "name": "music",
                    "icon": "music_cast"
                },
                {
                    "name": "todo",
                    "icon": "checklist"
                },
                {
                    "name": "sysmon",
                    "icon": "monitor_heart"
                }
            ],
            "ignoredTags": ["hide_in_bar", "xwl_popup"],
            "windowIcons": [
                {
                    "regex": "steam(_app_(default|[0-9]+))?",
                    "icon": "sports_esports"
                }
            ]
        },
        "tray": {
            "background": false,
            "recolour": false,
            "compact": false,
            "iconSubs": [],
            "hiddenIcons": []
        },
        "clock": {
            "background": false,
            "showDate": false,
            "showIcon": true
        },
        "sysMonitor": {
            "background": false,
            "showIcons": true,
            "showCpu": true,
            "showCpuTemp": true,
            "showMemory": true,
            "performance": {
                "showBattery": true,
                "showGpu": true,
                "showCpu": true,
                "showMemory": true,
                "showStorage": true,
                "showNetwork": true
            }
        },
        "statusIcons": [
            {
                "id": "lockStatus",
                "enabled": true
            },
            {
                "id": "audio",
                "enabled": false
            },
            {
                "id": "microphone",
                "enabled": false
            },
            {
                "id": "kbLayout",
                "enabled": false
            },
            {
                "id": "network",
                "enabled": true
            },
            {
                "id": "bluetooth",
                "enabled": true
            },
            {
                "id": "appVolumes",
                "enabled": true
            },
            {
                "id": "battery",
                "enabled": true
            }
        ],
        "entries": [
            {
                "id": "logo",
                "enabled": true
            },
            {
                "id": "workspaces",
                "enabled": true
            },
            {
                "id": "spacer",
                "enabled": true
            },
            {
                "id": "tray",
                "enabled": true
            },
            {
                "id": "sysmon",
                "enabled": true
            },
            {
                "id": "clock",
                "enabled": true
            },
            {
                "id": "statusIcons",
                "enabled": true
            },
            {
                "id": "power",
                "enabled": true
            }
        ],
        "excludedScreens": []
    },
    "border": {
        "thickness": 10,
        "rounding": 25,
        "smoothing": 20
    },
    "launcher": {
        "enabled": true,
        "spotlight": true,
        "dim": true,
        "showOnHover": false,
        "maxShown": 7,
        "maxWallpapers": 9,
        "specialPrefix": "@",
        "actionPrefix": ">",
        "enableDangerousActions": false,
        "dragThreshold": 50,
        "vimKeybinds": false,
        "favouriteApps": [],
        "hiddenApps": [],
        "useFuzzy": {
            "apps": false,
            "actions": false,
            "schemes": false,
            "variants": false,
            "wallpapers": false
        },
        "actions": [
            {
                "name": "Scheme",
                "icon": "palette",
                "description": "Change the current colour scheme",
                "command": ["autocomplete", "scheme"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Wallpaper",
                "icon": "image",
                "description": "Change the current wallpaper",
                "command": ["autocomplete", "wallpaper"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Variant",
                "icon": "colors",
                "description": "Change the current scheme variant",
                "command": ["autocomplete", "variant"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Random",
                "icon": "casino",
                "description": "Switch to a random wallpaper",
                "command": ["caelestia", "wallpaper", "-r"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Light",
                "icon": "light_mode",
                "description": "Change the scheme to light mode",
                "command": ["setMode", "light"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Dark",
                "icon": "dark_mode",
                "description": "Change the scheme to dark mode",
                "command": ["setMode", "dark"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Shutdown",
                "icon": "power_settings_new",
                "description": "Shutdown the system",
                "command": ["poweroff"],
                "enabled": true,
                "dangerous": true
            },
            {
                "name": "Reboot",
                "icon": "cached",
                "description": "Reboot the system",
                "command": ["reboot"],
                "enabled": true,
                "dangerous": true
            },
            {
                "name": "Logout",
                "icon": "exit_to_app",
                "description": "Log out of the current session",
                "command": ["logout"],
                "enabled": true,
                "dangerous": true
            },
            {
                "name": "Lock",
                "icon": "lock",
                "description": "Lock the current session",
                "command": ["loginctl", "lock-session"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Sleep",
                "icon": "bedtime",
                "description": "Suspend then hibernate",
                "command": ["suspendThenHibernate"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Settings",
                "icon": "settings",
                "description": "Configure the shell",
                "command": ["caelestia", "shell", "nexus", "open"],
                "enabled": true,
                "dangerous": false
            }
        ]
    },
    "lock": {
        "enabled": true,
        "useWallpaper": false,
        "enableFprint": true,
        "maxFprintTries": 3,
        "enableHowdy": true,
        "maxHowdyTries": 3,
        "triggerHowdyOnWake": true,
        "hideNotifs": false,
        "enableSessionControls": true
    },
    "nexus": {
        "wallpapersPerRow": 4,
        "networkRescanInterval": 15000
    },
    "notifs": {
        "expire": true,
        "fullscreen": "On",
        "defaultExpireTimeout": 5000,
        "fullscreenExpireTimeout": 2000,
        "clearThreshold": 0.3,
        "expandThreshold": 20,
        "actionOnClick": false,
        "groupPreviewNum": 3,
        "openExpanded": false
    },
    "osd": {
        "enabled": true,
        "hideDelay": 2000,
        "enableBrightness": true,
        "enableMicrophone": false
    },
    "services": {
        "sensorUnits": "Celsius",
        "dataUnits": "Binary",
        "clockFormat": "Auto",
        "gpuType": "Auto",
        "audioIncrement": 0.1,
        "brightnessIncrement": 0.1,
        "maxVolume": 1.0,
        "smartScheme": true,
        "resourceUpdateInterval": 1000
    },
    "session": {
        "enabled": true,
        "vimKeybinds": false,
        "icons": {
            "logout": "logout",
            "shutdown": "power_settings_new",
            "hibernate": "downloading",
            "reboot": "cached"
        },
        "commands": {
            "logout": ["logout"],
            "shutdown": ["poweroff"],
            "hibernate": ["hibernate"],
            "reboot": ["reboot"]
        }
    },
    "sidebar": {
        "enabled": true,
        "minHoverThreshold": 200
    },
    "utilities": {
        "enabled": true,
        "maxToasts": 4,
        "toasts": {
            "fullscreen": "off",
            "configLoaded": true,
            "chargingChanged": true,
            "gameModeChanged": true,
            "dndChanged": true,
            "audioOutputChanged": true,
            "audioInputChanged": true,
            "capsLockChanged": true,
            "numLockChanged": true,
            "kbLayoutChanged": true,
            "kbLimit": true,
            "vpnChanged": true
        },
        "vpn": {
            "enabled": false,
            "provider": [
                {
                    "name": "wireguard",
                    "interface": "your-connection-name",
                    "displayName": "Wireguard (Your VPN)",
                    "enabled": false
                }
            ]
        },
        "quickToggles": [
            {
                "id": "wifi",
                "enabled": true
            },
            {
                "id": "bluetooth",
                "enabled": true
            },
            {
                "id": "mic",
                "enabled": true
            },
            {
                "id": "settings",
                "enabled": true
            },
            {
                "id": "gameMode",
                "enabled": true
            },
            {
                "id": "dnd",
                "enabled": true
            },
            {
                "id": "vpn",
                "enabled": false
            }
        ],
        "gameMode": {
            "options": {
                "animations:enabled": 0,
                "decoration:blur:enabled": 0,
                "decoration:shadow:enabled": 0,
                "decoration:rounding": 0,
                "general:gaps_in": 0,
                "general:gaps_out": 0,
                "general:border_size": 1,
                "general:allow_tearing": 1
            }
        }
    },
    "paths": {
        "wallpaperDir": "~/Pictures/Wallpapers",
        "desktopDir": "~/Desktop",
        "noNotifsPic": "root:/assets/dino.png",
        "lockNoNotifsPic": "root:/assets/dino.png"
    }
}
```

</details>

### Advanced configuration

> [!CAUTION]
> Do not change these options unless you know what you are doing. They control
> the tokens used internally by the shell and can cause visual issues if
> modified incorrectly. The available options may change or be removed without
> notice across versions.

A separate `~/.config/caelestia/shell-tokens.json` file allows editing internal
tokens without touching the shell source. These tokens affect dimensions and
appearance, including rounding, spacing, padding, font sizes, animation
durations and curves, and component sizes. The appearance scale values in
`shell.json` are multiplied against these base tokens to produce the final
values.

Per-monitor token overrides are available at
`~/.config/caelestia/monitors/<monitor_name>/shell-tokens.json`.

## Credits

This fork is based on [Caelestia](https://github.com/caelestia-dots/shell/) —
the original shell.

Functionality inspiration:

- [cykler-caelestia](https://github.com/cykler01/cykler-caelestia)
- [lucid](https://github.com/Sn3akyy1/lucid)

The Caelestia Material icon theme uses folder art from
[Nordic](https://github.com/EliverLara/Nordic) by EliverLara.

Thanks also to [Quickshell](https://quickshell.outfoxxed.me) and
[Hyprland](https://hypr.land) for making this possible.
