pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.utils

Singleton {
    function launch(file: DesktopFile): void {
        if (!file)
            return;

        if (file.kind === "folder") {
            const explorer = GlobalConfig.general.apps.explorer;
            if (explorer.length > 0)
                Quickshell.execDetached({
                    command: [...explorer, file.path]
                });
            else
                Quickshell.execDetached(["xdg-open", file.path]);
            return;
        }

        if (file.kind !== "application") {
            Quickshell.execDetached(["xdg-open", file.path]);
            return;
        }

        if (file.command.length === 0)
            return;

        const workingDirectory = file.workingDirectory;

        if (file.terminal) {
            Quickshell.execDetached({
                command: [...GlobalConfig.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...file.command],
                workingDirectory
            });
        } else {
            Quickshell.execDetached({
                command: file.command,
                workingDirectory
            });
        }
    }

    function createFolder(): void {
        Quickshell.execDetached(["sh", "-c", `dir=$1
base=$2
mkdir -p -- "$dir"
dest="$dir/$base"
n=2
while [ -e "$dest" ] || [ -L "$dest" ]; do
    dest="$dir/$base $n"
    n=$((n + 1))
done
mkdir -- "$dest"`, "sh", Paths.desktop, "New Folder"]);
    }

    function createFile(): void {
        Quickshell.execDetached(["sh", "-c", `dir=$1
base=$2
mkdir -p -- "$dir"
name=\${base%.*}
ext=\${base##*.}
dest="$dir/$base"
n=2
while [ -e "$dest" ] || [ -L "$dest" ]; do
    dest="$dir/$name $n.$ext"
    n=$((n + 1))
done
: > "$dest"`, "sh", Paths.desktop, "New File.txt"]);
    }
}
