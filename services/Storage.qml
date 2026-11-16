pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string cacheDir: Quickshell.env("XDG_CACHE_HOME") || `${root.home}/.cache`
    readonly property string homeMount: {
        let best = "";
        for (const volume of root.volumes) {
            const prefix = volume.mount === "/" ? "/" : `${volume.mount}/`;
            if ((root.home === volume.mount || root.home.startsWith(prefix)) && volume.mount.length > best.length)
                best = volume.mount;
        }
        return best !== "" ? best : "/";
    }

    property var volumes: []
    property var homeDirs: []
    property var cleanups: []
    property real homeTotal: 0
    property bool volumesReady: false
    property bool measuring: false
    property double lastMeasured: 0
    property string cleaning: ""
    property string lastError: ""

    function refresh(force: bool): void {
        if (!dfProc.running)
            dfProc.running = true;

        root.measure(force);
    }

    function measure(force: bool): void {
        if (measureProc.running)
            return;

        if (!force && root.lastMeasured > 0 && Date.now() - root.lastMeasured < 30000)
            return;

        root.measuring = true;
        root.lastError = "";
        measureProc.running = true;
    }

    function clean(id: string): void {
        if (root.cleaning !== "")
            return;

        root.cleaning = id;
        root.lastError = "";

        if (id === "trash") {
            cleanProc.command = ["gio", "trash", "--empty"];
        } else if (id === "cache") {
            cleanProc.command = ["sh", "-c", `find "$1" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +`, "sh", root.cacheDir];
        } else if (id === "package") {
            cleanProc.command = ["pkexec", "pacman", "-Sc", "--noconfirm"];
        } else {
            root.cleaning = "";
            return;
        }

        cleanProc.running = true;
    }

    function openFolder(path: string): void {
        const explorer = GlobalConfig.general.apps.explorer;
        if (explorer.length > 0)
            Quickshell.execDetached({
                command: [...explorer, path]
            });
        else
            Quickshell.execDetached(["xdg-open", path]);
    }

    function formatSize(bytes: real): string {
        if (!bytes || bytes < 1)
            return "0 B";

        const units = ["B", "KB", "MB", "GB", "TB"];
        let value = bytes;
        let unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit++;
        }

        return `${unit === 0 || value >= 100 ? Math.round(value) : value.toFixed(1)} ${units[unit]}`;
    }

    function shortPath(path: string): string {
        if (path === root.home)
            return "~";
        if (path.startsWith(`${root.home}/`))
            return `~${path.substring(root.home.length)}`;
        return path;
    }

    function dirLabel(name: string): string {
        const labels = {
            ".cache": Tr.tr("Cache"),
            ".local": Tr.tr("Local data"),
            ".config": Tr.tr("Config"),
            ".var": Tr.tr("Flatpak data"),
            ".steam": Tr.tr("Steam"),
            ".cargo": Tr.tr("Rust data"),
            ".npm": Tr.tr("npm cache"),
            ".gemini": Tr.tr("Gemini data"),
            ".codex": Tr.tr("Codex data")
        };
        return labels[name] ?? name;
    }

    function dirIcon(name: string): string {
        const icons = {
            ".cache": "cached",
            ".local": "folder",
            ".config": "settings",
            ".var": "package_2",
            ".steam": "sports_esports",
            ".cargo": "code",
            ".npm": "code",
            ".gemini": "auto_awesome",
            ".codex": "code"
        };
        return icons[name] ?? "folder";
    }

    function parseVolumes(text: string): void {
        const found = [];
        const lines = text.trim().split("\n").slice(1);
        const ignoredTypes = ["tmpfs", "devtmpfs", "squashfs", "overlay", "efivarfs", "proc", "sysfs", "cgroup2", "devpts", "securityfs", "debugfs", "tracefs", "pstore", "bpf", "autofs", "mqueue", "hugetlbfs", "configfs", "fusectl", "ramfs"];

        for (const line of lines) {
            const fields = line.trim().split(/\s+/);
            if (fields.length < 7)
                continue;

            const type = fields[1];
            const size = Number(fields[2]);
            const used = Number(fields[3]);
            const avail = Number(fields[4]);
            const mount = fields.slice(6).join(" ");

            if (!mount.startsWith("/") || ignoredTypes.includes(type))
                continue;
            if (!Number.isFinite(size) || size < 1073741824)
                continue;

            found.push({
                fs: fields[0],
                type,
                mount,
                size,
                used,
                avail,
                percent: size > 0 ? Math.round((used / size) * 100) : 0
            });
        }

        const best = found.reduce((current, volume) => {
            const prefix = volume.mount === "/" ? "/" : `${volume.mount}/`;
            if ((root.home === volume.mount || root.home.startsWith(prefix)) && volume.mount.length > current.length)
                return volume.mount;
            return current;
        }, "");

        found.sort((a, b) => {
            const rank = volume => volume.mount === "/" ? 0 : volume.mount === best ? 1 : 2;
            const byRank = rank(a) - rank(b);
            return byRank !== 0 ? byRank : a.mount.localeCompare(b.mount);
        });

        root.volumes = found;
        root.volumesReady = true;
    }

    function parseMeasure(text: string): void {
        const dirs = [];
        const clean = {};
        let total = 0;
        let trashCount = 0;

        for (const line of text.trim().split("\n")) {
            const fields = line.split("\t");
            if (fields[0] === "dir") {
                dirs.push({
                    path: fields[2],
                    size: Number(fields[1])
                });
            } else if (fields[0] === "total") {
                total = Number(fields[1]);
            } else if (fields[0] === "clean") {
                clean[fields[1]] = Number(fields[2]);
            } else if (fields[0] === "count" && fields[1] === "trash") {
                trashCount = Number(fields[2]);
            }
        }

        dirs.sort((a, b) => b.size - a.size);
        root.homeTotal = total > 0 ? total : dirs.reduce((sum, dir) => sum + dir.size, 0);
        root.homeDirs = dirs.filter(dir => dir.size >= 1048576).map(dir => {
            const name = dir.path.substring(root.home.length + 1);
            return {
                path: dir.path,
                label: root.dirLabel(name),
                icon: root.dirIcon(name),
                size: dir.size
            };
        });

        const found = [];
        if (clean.trash !== undefined) {
            found.push({
                id: "trash",
                title: Tr.tr("Trash"),
                description: Tr.tr("%1 items deleted").arg(trashCount),
                confirm: Tr.tr("Empty the trash?"),
                action: Tr.tr("Empty"),
                icon: "delete",
                size: clean.trash
            });
        }
        if (clean.cache !== undefined) {
            found.push({
                id: "cache",
                title: Tr.tr("User cache"),
                description: Tr.tr("Temporary files that apps recreate"),
                confirm: Tr.tr("Clear the user cache?"),
                action: Tr.tr("Clear"),
                icon: "cached",
                size: clean.cache
            });
        }
        if (clean.package !== undefined) {
            found.push({
                id: "package",
                title: Tr.tr("Package cache"),
                description: Tr.tr("Downloaded packages. Asks for your password."),
                confirm: Tr.tr("Clean the package cache?"),
                action: Tr.tr("Clean"),
                icon: "inventory_2",
                root: true,
                size: clean.package
            });
        }

        root.cleanups = found;
        root.lastMeasured = Date.now();
    }

    Process {
        id: dfProc

        command: ["df", "-P", "-B1", "-T"]
        stdout: StdioCollector {
            onStreamFinished: root.parseVolumes(text)
        }
        onExited: root.volumesReady = true
    }

    Process {
        id: measureProc

        command: ["nice", "-n", "10", "sh", "-c", `home=$1
cache=$2
emit() {
    id=$1
    path=$2
    [ -e "$path" ] || return
    size=$(du -sb --one-file-system -- "$path" 2>/dev/null | cut -f1)
    [ -n "$size" ] && printf 'clean\\t%s\\t%s\\n' "$id" "$size"
}
du -x -d1 -B1 -- "$home" 2>/dev/null | while read -r size path; do
    if [ "$path" = "$home" ]; then
        printf 'total\\t%s\\n' "$size"
    else
        printf 'dir\\t%s\\t%s\\n' "$size" "$path"
    fi
done
emit cache "$cache"
emit trash "$home/.local/share/Trash/files"
emit package "/var/cache/pacman/pkg"
count=$(find "$home/.local/share/Trash/files" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
printf 'count\\ttrash\\t%s\\n' "$count"`, "sh", root.home, root.cacheDir]
        stdout: StdioCollector {
            onStreamFinished: root.parseMeasure(text)
        }
        onExited: root.measuring = false
    }

    Process {
        id: cleanProc

        onExited: code => {
            const failed = code !== 0;
            const id = root.cleaning;
            root.cleaning = "";

            if (failed) {
                root.lastError = Tr.tr("Cleanup failed");
                Toaster.toast(Tr.tr("Storage cleanup failed"), Tr.tr("The command did not finish successfully"), "error", Toast.Error);
            } else {
                root.cleanups = root.cleanups.map(item => item.id === id ? Object.assign({}, item, {
                        size: 0
                    }) : item);
                Toaster.toast(Tr.tr("Storage cleaned"), Tr.tr("Space has been freed"), "delete_sweep", Toast.Success);
            }

            root.refresh(true);
        }
    }
}
