#!/system/bin/sh
MODPATH="${0%/*}"
BOX=/data/adb/Box-Brain
CHANGED=0

# Scripts-only mode must leave the ROM's own spoofing in control.
[ -d "$MODPATH/zygisk" ] && [ ! -f "$MODPATH/scripts-only-mode" ] || exit 0

# Newer ROMs store built-in PIF settings here instead of using persist props.
# Settings may be unavailable in recovery; service.sh handles it after boot.
if [ ! -f "$MODPATH/skippersistprop" ]; then
    if ROM_PIF=$(settings --user 0 get secure spoof_pif_config 2>/dev/null); then
        case "$ROM_PIF" in
            ''|null) ;;
            *)
                mkdir -p "$BOX" || exit 1
                if [ ! -f "$BOX/rom-pif-config" ]; then
                    (umask 077; printf '%s\n' "$ROM_PIF" > "$BOX/rom-pif-config") || exit 1
                fi
                settings --user 0 delete secure spoof_pif_config >/dev/null || exit 1
                echo "- Disabled conflicting ROM PIF configuration"
                CHANGED=1
                ;;
        esac
    fi
fi

if [ "$CHANGED" = 1 ] && [ "$1" = --restart ]; then
    sh "$MODPATH/killpi.sh" >/dev/null 2>&1 || true
fi
exit 0
