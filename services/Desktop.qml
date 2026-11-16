pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Models

Singleton {
    function launch(file: DesktopFile): void {
        if (!file || file.command.length === 0)
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
}
