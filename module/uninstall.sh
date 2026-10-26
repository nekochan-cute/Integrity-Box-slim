# common_setup.sh also runs this to revert persist props, only clean up on removal
if [ -f /data/adb/modules/playintegrityfix/remove ]; then
    for FILE in /data/adb/tricky_store/keybox.xml /data/adb/tricky_store/target.txt; do
        [ -f $FILE.bak ] && mv -f $FILE.bak $FILE
    done
    rm -rf /data/adb/Box-Brain
fi
