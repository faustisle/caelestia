#!/bin/sh

# Privileged storage cleanup actions are run inside a terminal so sudo can
# prompt for a password. Avoid pkexec here: without a polkit agent it waits
# forever for a text prompt that the shell has no terminal for.

case "${1:-}" in
    package)
        /usr/bin/sudo /usr/bin/pacman -Sc --noconfirm
        ;;
    orphans)
        names=$(/usr/bin/pacman -Qdtq 2>/dev/null)
        if [ -n "$names" ]; then
            /usr/bin/sudo /usr/bin/pacman -Rns --noconfirm $names
        fi
        ;;
    journal)
        /usr/bin/sudo /usr/bin/journalctl --vacuum-size=200M
        ;;
    coredumps)
        /usr/bin/sudo /usr/bin/find /var/lib/systemd/coredump -mindepth 1 -type f -delete
        ;;
    *)
        echo "Unknown storage cleanup: ${1:-}"
        exit 2
        ;;
esac

status=$?
if [ "$status" -ne 0 ]; then
    printf '\nThe cleanup did not finish. Closing in 3 seconds...\n'
    sleep 3
fi
exit "$status"
