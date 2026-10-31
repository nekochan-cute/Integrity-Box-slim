#!/system/bin/sh
MODPATH="${0%/*}"
BOX=/data/adb/Box-Brain
TS=/data/adb/tricky_store
TS_MODULE=/data/adb/modules/tricky_store
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

if [ -d "$TS_MODULE" ] && [ ! -f "$TS_MODULE/disable" ] &&
   [ ! -f "$TS_MODULE/remove" ] && [ -s "$TS/keybox.xml" ]; then
    PIF="$MODPATH/custom.pif.prop"
    if [ ! -f "$PIF" ] && [ -f "$MODPATH/custom.pif.json" ]; then
        sh "$MODPATH/migrate.sh" --install --force --advanced --prop "$MODPATH/custom.pif.json" || exit 1
        mv -f "$MODPATH/custom.pif.json" "$MODPATH/custom.pif.json.bak" || exit 1
        CHANGED=1
    fi
    if [ -f "$PIF" ]; then
        # Keep AndroidKeyStore available for Tricky Store hardware attestation.
        if grep -q '^[[:space:]]*spoofProvider[[:space:]]*=' "$PIF"; then
            if grep '^[[:space:]]*spoofProvider[[:space:]]*=' "$PIF" | grep -qvE '^[[:space:]]*spoofProvider[[:space:]]*=[[:space:]]*0[[:space:]]*(#.*)?$'; then
                sed -i 's/^[[:space:]]*spoofProvider[[:space:]]*=.*/spoofProvider=0/' "$PIF" || exit 1
                CHANGED=1
            fi
        else
            printf '\nspoofProvider=0\n' >> "$PIF" || exit 1
            CHANGED=1
        fi

    fi
fi

if [ "$CHANGED" = 1 ] && [ "$1" = --restart ]; then
    sh "$MODPATH/killpi.sh" >/dev/null 2>&1 || true
fi
exit 0
