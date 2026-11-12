import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    // Whether the launcher was opened from the bar button, which always opens
    // the regular (corner) launcher instead of the configured spotlight mode.
    property bool launcherRegular
    property bool utilities
    property bool sidebar
}
