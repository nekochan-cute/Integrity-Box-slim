# common_setup.sh also runs this to revert persist props, only clean up on removal
if [ -f /data/adb/modules/playintegrityfix/remove ]; then
    # Do not overwrite a ROM configuration the user has changed since install.
    if [ -f /data/adb/Box-Brain/rom-pif-config ]; then
        ROM_PIF=$(settings --user 0 get secure spoof_pif_config 2>/dev/null) || exit 1
        case "$ROM_PIF" in
            ''|null)
                settings --user 0 put secure spoof_pif_config "$(cat /data/adb/Box-Brain/rom-pif-config)" || exit 1
                ;;
        esac
    fi
    for FILE in /data/adb/tricky_store/keybox.xml /data/adb/tricky_store/target.txt; do
        [ -f $FILE.bak ] && mv -f $FILE.bak $FILE
    done
    rm -rf /data/adb/Box-Brain
fi
