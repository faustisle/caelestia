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
    property var systemItems: []
    property var cacheItems: []
    property var reviewItems: []
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

    function clean(item: var): void {
        if (!item || root.cleaning !== "")
            return;

        root.cleaning = item.id;
        root.lastError = "";

        if (item.kind === "trash") {
            cleanProc.command = ["gio", "trash", "--empty"];
        } else if (item.kind === "cache") {
            cleanProc.command = ["sh", "-c", `find "$1" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +`, "sh", item.path];
        } else if (["package", "orphans", "journal", "coredumps"].includes(item.kind)) {
            const terminal = GlobalConfig.general.apps.terminal;
            if (terminal.length === 0) {
                root.cleaning = "";
                root.lastError = Tr.tr("No terminal is configured");
                Toaster.toast(Tr.tr("Storage cleanup failed"), Tr.tr("No terminal is configured"), "error", Toast.Error);
                return;
            }

            // Run in the terminal so sudo can prompt. pkexec has no usable
            // authentication agent here and waits forever for a text prompt.
            cleanProc.command = [...terminal, "sh", Quickshell.shellPath("assets/storage_clean.sh"), item.kind];
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

    function parseHumanSize(value: string): real {
        const match = String(value).trim().match(/^([\d.]+)\s*([KMGT]?)i?B?$/i);
        if (!match)
            return 0;

        const units = {
            "": 1,
            K: 1024,
            M: 1024 * 1024,
            G: 1024 * 1024 * 1024,
            T: 1024 * 1024 * 1024 * 1024
        };
        return Math.round(parseFloat(match[1]) * (units[match[2].toUpperCase()] ?? 1));
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

    function cacheInfo(id: string): var {
        const info = {
            thumbnails: {
                title: Tr.tr("Thumbnails"),
                icon: "image",
                note: Tr.tr("Preview images, recreated when folders are opened.")
            },
            pip: {
                title: Tr.tr("pip downloads"),
                icon: "download",
                note: Tr.tr("Python packages, fetched again when needed.")
            },
            yay: {
                title: Tr.tr("yay build files"),
                icon: "build",
                note: Tr.tr("Leftover AUR build files.")
            },
            paru: {
                title: Tr.tr("paru build files"),
                icon: "build",
                note: Tr.tr("Leftover AUR build files.")
            },
            npm: {
                title: Tr.tr("npm cache"),
                icon: "code",
                note: Tr.tr("JavaScript packages, fetched again when needed.")
            },
            yarn: {
                title: Tr.tr("Yarn cache"),
                icon: "code",
                note: Tr.tr("JavaScript packages, fetched again when needed.")
            },
            bun: {
                title: Tr.tr("Bun cache"),
                icon: "code",
                note: Tr.tr("JavaScript packages, fetched again when needed.")
            },
            gobuild: {
                title: Tr.tr("Go build cache"),
                icon: "code",
                note: Tr.tr("Compiled Go packages, rebuilt when needed.")
            },
            nodegyp: {
                title: Tr.tr("node-gyp headers"),
                icon: "code",
                note: Tr.tr("Headers for native Node modules, downloaded again when needed.")
            },
            cargo: {
                title: Tr.tr("Cargo registry"),
                icon: "code",
                note: Tr.tr("Rust crates, fetched again on the next build.")
            },
            gradle: {
                title: Tr.tr("Gradle caches"),
                icon: "code",
                note: Tr.tr("Java build dependencies, fetched again when needed.")
            },
            maven: {
                title: Tr.tr("Maven repository"),
                icon: "code",
                note: Tr.tr("Java build dependencies, fetched again when needed.")
            },
            electron: {
                title: Tr.tr("Electron downloads"),
                icon: "download",
                note: Tr.tr("Electron builds used by development tools.")
            },
            composer: {
                title: Tr.tr("Composer cache"),
                icon: "code",
                note: Tr.tr("PHP packages downloaded by Composer.")
            },
            shaders: {
                title: Tr.tr("Shader caches"),
                icon: "memory",
                note: Tr.tr("Compiled shaders, rebuilt by apps when needed.")
            }
        };
        return info[id] ?? null;
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
        const cacheEntries = [];
        const orphanNames = [];
        const clean = {};
        let total = 0;
        let trashCount = 0;
        let orphanCount = 0;
        let orphanSize = 0;
        let journalTotal = 0;
        let coredumpSize = 0;
        let coredumpCount = 0;

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
            } else if (fields[0] === "cache") {
                cacheEntries.push({
                    id: fields[1],
                    size: Number(fields[2]),
                    path: fields[3]
                });
            } else if (fields[0] === "orphans") {
                orphanCount = Number(fields[1]);
            } else if (fields[0] === "orphansize") {
                orphanNames.push(fields[1]);
                orphanSize += root.parseHumanSize(fields[2]);
            } else if (fields[0] === "journal") {
                journalTotal = root.parseHumanSize(fields[1]);
            } else if (fields[0] === "coredumps") {
                coredumpSize = Number(fields[1]);
                coredumpCount = Number(fields[2]);
            }
        }

        dirs.sort((a, b) => b.size - a.size);
        const cacheDirEntry = dirs.find(dir => dir.path === root.cacheDir);
        const cacheTotal = cacheDirEntry ? cacheDirEntry.size : 0;

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

        const caches = [];
        let curatedInCache = 0;
        for (const entry of cacheEntries) {
            if (entry.size < 8388608)
                continue;

            const info = root.cacheInfo(entry.id);
            if (!info)
                continue;

            caches.push({
                id: `cache:${entry.id}`,
                kind: "cache",
                title: info.title,
                description: info.note,
                confirm: Tr.tr("Clear %1?").arg(info.title.toLowerCase()),
                action: Tr.tr("Clear"),
                icon: info.icon,
                size: entry.size,
                path: entry.path,
                removable: true
            });

            if (entry.path.startsWith(`${root.cacheDir}/`))
                curatedInCache += entry.size;
        }

        const cacheList = [];
        if (clean.trash !== undefined && clean.trash > 0) {
            cacheList.push({
                id: "trash",
                kind: "trash",
                title: Tr.tr("Trash"),
                description: Tr.tr("%1 items you deleted").arg(trashCount),
                confirm: Tr.tr("Empty the trash?"),
                action: Tr.tr("Empty"),
                icon: "delete",
                size: clean.trash,
                removable: true
            });
        }

        cacheList.push(...caches);
        cacheList.sort((a, b) => b.size - a.size);

        const review = [];
        const otherCaches = Math.max(0, cacheTotal - curatedInCache);
        if (otherCaches >= 8388608) {
            review.push({
                id: "othercaches",
                kind: "review",
                title: Tr.tr("Other app caches"),
                description: Tr.tr("Caches not listed above. Open the folder to inspect them."),
                confirm: "",
                action: Tr.tr("Show"),
                icon: "folder",
                size: otherCaches,
                path: root.cacheDir,
                removable: false
            });
        }

        const system = [];
        if (clean.package !== undefined && clean.package > 0) {
            system.push({
                id: "package",
                kind: "package",
                title: Tr.tr("Old package downloads"),
                description: Tr.tr("Downloaded packages. Asks for your password."),
                confirm: Tr.tr("Clean the package cache?"),
                action: Tr.tr("Clean"),
                icon: "inventory_2",
                size: clean.package,
                root: true,
                removable: true
            });
        }

        if (orphanCount > 0) {
            const names = orphanNames.slice(0, 3).join(", ");
            const summary = orphanNames.length > 3 ? Tr.tr("%1 and %2 more").arg(names).arg(orphanNames.length - 3) : names;
            system.push({
                id: "orphans",
                kind: "orphans",
                title: Tr.tr("Unused dependencies"),
                description: Tr.tr("%1 packages were installed for something that is gone: %2. Asks for your password.").arg(orphanCount).arg(summary),
                details: orphanNames.join(", "),
                confirm: Tr.tr("Remove %1 unused packages?").arg(orphanCount),
                action: Tr.tr("Remove"),
                icon: "extension_off",
                size: orphanSize,
                root: true,
                removable: true
            });
        }

        const journalKeep = 200 * 1024 * 1024;
        if (journalTotal > journalKeep) {
            system.push({
                id: "journal",
                kind: "journal",
                title: Tr.tr("System logs"),
                description: Tr.tr("The journal takes %1. Shrinking keeps the newest 200 MB. Asks for your password.").arg(root.formatSize(journalTotal)),
                confirm: Tr.tr("Shrink the system logs?"),
                action: Tr.tr("Shrink"),
                icon: "description",
                size: journalTotal - journalKeep,
                root: true,
                removable: true
            });
        }

        if (coredumpSize > 0) {
            system.push({
                id: "coredumps",
                kind: "coredumps",
                title: Tr.tr("Crash dumps"),
                description: Tr.tr("%1 memory snapshots from crashed programs. Asks for your password.").arg(coredumpCount),
                confirm: Tr.tr("Delete the crash dumps?"),
                action: Tr.tr("Delete"),
                icon: "bug_report",
                size: coredumpSize,
                root: true,
                removable: true
            });
        }

        system.sort((a, b) => b.size - a.size);

        root.systemItems = system;
        root.cacheItems = cacheList;
        root.reviewItems = review;
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
emitcache() {
    id=$1
    path=$2
    [ -e "$path" ] || return
    size=$(du -sb --one-file-system -- "$path" 2>/dev/null | cut -f1)
    [ -n "$size" ] && printf 'cache\\t%s\\t%s\\t%s\\n' "$id" "$size" "$path"
}
du -x -d1 -B1 -- "$home" 2>/dev/null | while read -r size path; do
    if [ "$path" = "$home" ]; then
        printf 'total\\t%s\\n' "$size"
    else
        printf 'dir\\t%s\\t%s\\n' "$size" "$path"
    fi
done
emit trash "$home/.local/share/Trash/files"
emit package "/var/cache/pacman/pkg"
emitcache thumbnails "$cache/thumbnails"
emitcache pip "$cache/pip"
emitcache yay "$cache/yay"
emitcache paru "$cache/paru"
emitcache npm "$home/.npm/_cacache"
emitcache yarn "$cache/yarn"
emitcache bun "$home/.bun/install/cache"
emitcache gobuild "$cache/go-build"
emitcache nodegyp "$cache/node-gyp"
emitcache cargo "$home/.cargo/registry"
emitcache gradle "$home/.gradle/caches"
emitcache maven "$home/.m2/repository"
emitcache electron "$cache/electron"
emitcache composer "$cache/composer"
emitcache shaders "$cache/mesa_shader_cache"
count=$(find "$home/.local/share/Trash/files" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
printf 'count\\ttrash\\t%s\\n' "$count"
if command -v pacman >/dev/null 2>&1; then
    names=$(pacman -Qdtq 2>/dev/null)
    if [ -n "$names" ]; then
        count=$(printf '%s\\n' "$names" | wc -l)
        printf 'orphans\\t%s\\n' "$count"
        LANG=C pacman -Qi $names 2>/dev/null | awk -F: '
            /^Name/ {name=$2; sub(/^[ \\t]+/,"",name)}
            /^Installed Size/ {size=$2; sub(/^[ \\t]+/,"",size); print "orphansize\\t" name "\\t" size}
        '
    fi
fi
if command -v journalctl >/dev/null 2>&1; then
    journal=$(journalctl --disk-usage 2>/dev/null | sed -n 's/.*take up \\([0-9.]*[KMGTP]\\).*/\\1/p' | head -1)
    [ -n "$journal" ] && printf 'journal\\t%s\\n' "$journal"
fi
if [ -d /var/lib/systemd/coredump ]; then
    size=$(du -sb --one-file-system /var/lib/systemd/coredump 2>/dev/null | cut -f1)
    count=$(find /var/lib/systemd/coredump -mindepth 1 -maxdepth 1 -type f 2>/dev/null | wc -l)
    [ -n "$size" ] && printf 'coredumps\\t%s\\t%s\\n' "$size" "$count"
fi`, "sh", root.home, root.cacheDir]
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
                const zero = items => items.map(item => item.id === id ? Object.assign({}, item, {
                            size: 0
                        }) : item);
                root.cacheItems = zero(root.cacheItems);
                root.systemItems = zero(root.systemItems);
                Toaster.toast(Tr.tr("Storage cleaned"), Tr.tr("Space has been freed"), "delete_sweep", Toast.Success);
            }

            root.refresh(true);
        }
    }
}
