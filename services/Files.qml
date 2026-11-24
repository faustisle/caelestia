pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services
import qs.utils
import qs.modules.files

Singleton {
    id: root

    property var clipboard: ({
            paths: [],
            cut: false
        })

    property real iconScale: 1

    readonly property bool hasClipboard: root.clipboard.paths.length > 0
    readonly property real minIconScale: 0.8
    readonly property real maxIconScale: 2.0

    readonly property string trashPath: `${Quickshell.env("XDG_DATA_HOME") || `${Paths.home}/.local/share`}/Trash/files`

    function clampIconScale(value: real): real {
        return Math.max(root.minIconScale, Math.min(root.maxIconScale, value));
    }

    function setIconScale(value: real): void {
        const next = root.clampIconScale(value);
        if (next === root.iconScale)
            return;
        root.iconScale = next;
        stateSaveTimer.restart();
    }

    function saveState(): void {
        stateFile.setText(JSON.stringify({
            iconScale: root.iconScale
        }));
    }

    function resolvePath(path: string): string {
        let resolved = path.trim();
        if (!resolved)
            return "";

        if (resolved.startsWith("file://"))
            return Paths.toLocalFile(resolved);

        if (!resolved.startsWith("/") && !resolved.startsWith("~") && !resolved.startsWith("$"))
            resolved = `${Paths.home}/${resolved}`;

        return Paths.absolutePath(resolved);
    }

    function open(path: string): void {
        const localPath = root.resolvePath(path);
        if (!localPath)
            return;

        const window = windowComp.createObject(windowHolder, {
            startPath: localPath
        });
        if (!window)
            return;

        window.visible = true;
        if (window.requestActivate)
            window.requestActivate();
    }

    function openPath(path: string): void {
        if (!path)
            return;

        if (Images.isValidImageByName(path)) {
            ImageViewer.open(path);
            return;
        }

        Quickshell.execDetached(["xdg-open", path]);
    }

    function openTerminal(path: string): void {
        const terminal = GlobalConfig.general.apps.terminal;
        if (terminal.length === 0)
            return;

        Quickshell.execDetached({
            command: terminal,
            workingDirectory: path
        });
    }

    function launchWith(app: var, path: string): void {
        if (!app || app.command.length === 0)
            return;

        const workingDirectory = app.workingDirectory || path.slice(0, path.lastIndexOf("/"));
        const terminal = app.terminal ?? app.runInTerminal;

        if (terminal) {
            Quickshell.execDetached({
                command: [...GlobalConfig.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...app.command, path],
                workingDirectory
            });
        } else {
            Quickshell.execDetached({
                command: [...app.command, path],
                workingDirectory
            });
        }
    }

    function copy(paths: list<string>, cut: bool): void {
        if (paths.length === 0)
            return;

        root.clipboard = {
            paths: paths.slice(),
            cut: cut
        };
        root.setClipboard(paths);
    }

    function setClipboard(paths: list<string>): void {
        const uris = paths.map(path => root.fileUri(path));
        Quickshell.execDetached(["sh", "-c", `printf '%s\n' "$@" | wl-copy --type text/uri-list`, "sh", ...uris]);
    }

    function paste(destination: string): void {
        const paths = root.clipboard.paths;
        if (paths.length === 0)
            return;

        const mode = root.clipboard.cut ? "cut" : "copy";
        Quickshell.execDetached(["sh", "-c", `mode=$1
dest=$2
shift 2
for src in "$@"; do
    [ -e "$src" ] || [ -L "$src" ] || continue
    base=$(basename -- "$src")
    case "$base" in
        *.*) name=\${base%.*}; ext=.\${base##*.} ;;
        *) name=$base; ext= ;;
    esac
    [ -n "$name" ] || { name=$base; ext=; }
    target="$dest/$base"
    n=2
    while [ -e "$target" ] || [ -L "$target" ]; do
        target="$dest/$name ($n)$ext"
        n=$((n + 1))
    done
    if [ "$mode" = cut ]; then
        mv -- "$src" "$target"
    else
        cp -a -- "$src" "$target"
    fi
done`, "sh", mode, destination, ...paths]);

        if (root.clipboard.cut)
            root.clipboard = {
                paths: [],
                cut: false
            };
    }

    function createFolder(directory: string, name: string): void {
        if (!name.trim())
            return;

        Quickshell.execDetached(["sh", "-c", `dir=$1
base=$2
dest="$dir/$base"
n=2
while [ -e "$dest" ] || [ -L "$dest" ]; do
    dest="$dir/$base $n"
    n=$((n + 1))
done
mkdir -- "$dest"`, "sh", directory, name.trim()]);
    }

    function createFile(directory: string, name: string): void {
        if (!name.trim())
            return;

        Quickshell.execDetached(["sh", "-c", `dir=$1
base=$2
name=\${base%.*}
ext=\${base##*.}
dest="$dir/$base"
n=2
while [ -e "$dest" ] || [ -L "$dest" ]; do
    dest="$dir/$name $n.$ext"
    n=$((n + 1))
done
: > "$dest"`, "sh", directory, name.trim()]);
    }

    function renameEntry(path: string, name: string): void {
        if (!path || !name.trim() || name.includes("/"))
            return;

        const slash = path.lastIndexOf("/");
        if (slash <= 0)
            return;

        const destination = `${path.slice(0, slash)}/${name.trim()}`;
        Quickshell.execDetached(["sh", "-c", `if [ -e "$2" ] || [ -L "$2" ]; then exit 1; fi
mv -- "$1" "$2"`, "sh", path, destination]);
    }

    function trash(paths: list<string>): void {
        if (paths.length > 0)
            Quickshell.execDetached(["gio", "trash", "--", ...paths]);
    }

    function deletePermanently(paths: list<string>): void {
        if (paths.length > 0)
            Quickshell.execDetached(["rm", "-rf", "--", ...paths]);
    }

    function emptyTrash(): void {
        Quickshell.execDetached(["gio", "trash", "--empty"]);
    }

    function compress(paths: list<string>, destination: string, name: string): void {
        if (paths.length === 0 || !name.trim())
            return;

        Quickshell.execDetached(["sh", "-c", `dest=$1
name=$2
shift 2
case "$name" in
    *.zip) ;;
    *) name="$name.zip" ;;
esac
base=\${name%.zip}
target="$dest/$name"
n=2
while [ -e "$target" ]; do
    target="$dest/$base ($n).zip"
    n=$((n + 1))
done
7z a -tzip "$target" "$@"`, "sh", destination, name.trim(), ...paths]);
    }

    function extract(archive: string, destination: string, folderName: string): void {
        if (!archive)
            return;

        Quickshell.execDetached(["sh", "-c", `dest=$1
archive=$2
folder=$3
if [ -n "$folder" ]; then
    base=$folder
    target="$dest/$base"
    n=2
    while [ -e "$target" ]; do
        target="$dest/$base ($n)"
        n=$((n + 1))
    done
    dest=$target
fi
mkdir -p -- "$dest"
case "$archive" in
    *.tar|*.tar.gz|*.tar.bz2|*.tar.xz|*.tar.zst|*.tgz|*.tbz2|*.txz)
        bsdtar -xf "$archive" -C "$dest" ;;
    *)
        7z x -y -o"$dest" "$archive" ;;
esac`, "sh", destination, archive, folderName]);
    }

    function isArchive(entry: FileSystemEntry): bool {
        if (!entry || entry.isDir)
            return false;

        const name = entry.name.toLowerCase();
        return /\.(zip|7z|rar|tar|tgz|tbz2|txz|tar\.gz|tar\.bz2|tar\.xz|tar\.zst|gz|bz2|xz|zst)$/.test(name);
    }

    function archiveBaseName(entry: FileSystemEntry): string {
        if (!entry)
            return "";

        return entry.name.replace(/\.(tar\.(gz|bz2|xz|zst)|zip|7z|rar|tgz|tbz2|txz|gz|bz2|xz|zst)$/i, "") || entry.name;
    }

    function fileUri(path: string): string {
        return `file://${path.split("/").map(encodeURIComponent).join("/")}`;
    }

    IpcHandler {
        function open(path: string): void {
            root.open(path);
        }

        target: "files"
    }

    FileView {
        id: stateFile

        printErrors: false
        path: `${Paths.state}/files.json`

        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (typeof data.iconScale === "number" && !isNaN(data.iconScale))
                    root.iconScale = root.clampIconScale(data.iconScale);
            } catch (e) {
            }
        }
    }

    Timer {
        id: stateSaveTimer

        interval: 300
        onTriggered: root.saveState()
    }

    QtObject {
        id: windowHolder
    }

    Component {
        id: windowComp

        FilesWindow {}
    }
}
