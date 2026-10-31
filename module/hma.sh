#!/system/bin/sh
# Apply Integrity Box's Hide My Applist config, ported from Integrity Box's hma.sh.
# usage: sh hma.sh [--status]
MODPATH="${0%/*}"
SRC="$MODPATH/hma-config.json"
BACKUP_DIR=/data/adb/HMA

PACKAGES=$(pm list packages 2>/dev/null)
APP=
for PKG in org.frknkrc44.hma_oss com.google.android.hmal com.tsng.hidemyapplist; do
    echo "$PACKAGES" | grep -qx "package:$PKG" && APP=$PKG && break
done

CONFIG=
case $APP in
    org.frknkrc44.hma_oss)
        # HMA-OSS keeps its config in its system service's data directory
        ACTIVITY=$APP/.ui.activity.MainActivity
        for DIR in /data/misc/hide_my_applist_*; do
            [ -d "$DIR" ] && CONFIG=$DIR/config.json && break
        done
        ;;
    ?*)
        # Hide My Applist loads the app's own config on launch and syncs it to its service
        ACTIVITY=$APP/icu.nullptr.hidemyapplist.ui.activity.MainActivity
        CONFIG=/data/data/$APP/files/config.json
        ;;
esac

if [ "$1" = --status ]; then
    echo "app=$APP"
    [ -f "$CONFIG" ] && echo "config=$CONFIG"
    exit 0
fi

[ -f "$SRC" ] || { echo "! $SRC is missing"; exit 1; }

if [ -z "$APP" ]; then
    echo "! Hide My Applist is not installed, opening the HMA-OSS releases page"
    am start -a android.intent.action.VIEW -d https://github.com/frknkrc44/HMA-OSS/releases >/dev/null 2>&1
    exit 1
fi
echo "- Found $APP"

if [ -z "$CONFIG" ]; then
    echo "! The HMA-OSS service is not running, no data directory in /data/misc"
    exit 1
fi

if [ "$APP" != org.frknkrc44.hma_oss ] && [ ! -f "$CONFIG" ]; then
    echo "- Launching $APP to create its config"
    am start --user 0 -n "$ACTIVITY" >/dev/null 2>&1
    i=0
    until [ -f "$CONFIG" ]; do
        [ $i -ge 15 ] && { echo "! $APP did not create $CONFIG"; exit 1; }
        sleep 1
        i=$((i + 1))
    done
fi

am force-stop "$APP"

BACKUP=
if [ -f "$CONFIG" ]; then
    mkdir -p $BACKUP_DIR
    BACKUP=$BACKUP_DIR/config_$(date +%Y-%m-%d_%H-%M-%S).json
    cp -f "$CONFIG" "$BACKUP" || { echo "! Failed to back up $CONFIG"; exit 1; }
    echo "- Backed up the current config to $BACKUP"
    # Writing into the existing file keeps its owner and SELinux label,
    # so SELinux does not have to be switched to permissive.
    cat "$SRC" > "$CONFIG" || { echo "! Failed to write $CONFIG"; exit 1; }
else
    DIR=${CONFIG%/*}
    cp -f "$SRC" "$CONFIG" &&
        chown "$(stat -c %u:%g "$DIR")" "$CONFIG" &&
        chmod 600 "$CONFIG" &&
        chcon "$(stat -c %C "$DIR")" "$CONFIG" || { echo "! Failed to write $CONFIG"; exit 1; }
fi
echo "- Wrote the Integrity Box config to $CONFIG"

if [ "$APP" = org.frknkrc44.hma_oss ]; then
    am start --user 0 -n "$ACTIVITY" >/dev/null 2>&1
    echo "- The HMA-OSS service loads the config after a reboot, or right away when the status card in HMA-OSS is long-pressed"
    exit 0
fi

am start --user 0 -n "$ACTIVITY" >/dev/null 2>&1 || echo "! Could not launch $APP"
# The app rewrites the config in its own format when it syncs it to the service
i=0
while cmp -s "$SRC" "$CONFIG"; do
    if [ $i -ge 15 ]; then
        am force-stop "$APP"
        cat "$BACKUP" > "$CONFIG"
        echo "! $APP did not load the config, restored the previous one"
        exit 1
    fi
    sleep 1
    i=$((i + 1))
done
echo "- $APP loaded the config and synced it to its service"
