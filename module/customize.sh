# Integrity Box's scripts-only flag
if [ -f /data/adb/Box-Brain/zygisk ]; then
    mkdir -p /data/adb/modules/playintegrityfix
    mv -f /data/adb/Box-Brain/zygisk /data/adb/modules/playintegrityfix/scripts-only-mode
fi

# Allow a scripts-only mode for older Android (<10) which may not require the Zygisk components
if [ -f /data/adb/modules/playintegrityfix/scripts-only-mode ]; then
    ui_print "! Installing global scripts only; Zygisk attestation fallback and device spoofing disabled"
    touch $MODPATH/scripts-only-mode
    sed -i 's/\(description=\)\(.*\)/\1[Scripts-only mode] \2/' $MODPATH/module.prop
    [ -f /data/adb/modules/playintegrityfix/uninstall.sh ] && sh /data/adb/modules/playintegrityfix/uninstall.sh
    rm -rf $MODPATH/app_replace_list.txt \
        $MODPATH/autopif4.sh $MODPATH/classes.dex \
        $MODPATH/common_setup.sh $MODPATH/custom.app_replace_list.txt \
        $MODPATH/custom.pif.json $MODPATH/custom.pif.prop  \
        $MODPATH/example.pif.json $MODPATH/example.pif.prop $MODPATH/migrate.sh \
        $MODPATH/pif.json $MODPATH/pif.prop $MODPATH/zygisk \
        /data/adb/modules/playintegrityfix/custom.app_replace_list.txt \
        /data/adb/modules/playintegrityfix/custom.pif.json \
        /data/adb/modules/playintegrityfix/custom.pif.prop \
        /data/adb/modules/playintegrityfix/skipmatchdevice \
        /data/adb/modules/playintegrityfix/skippersistprop \
        /data/adb/modules/playintegrityfix/system \
        /data/adb/modules/playintegrityfix/uninstall.sh
fi

# Copy any disabled app files to updated module
if [ -d /data/adb/modules/playintegrityfix/system ]; then
    ui_print "- Restoring disabled ROM apps configuration"
    cp -afL /data/adb/modules/playintegrityfix/system $MODPATH
fi

# Copy any supported custom files to updated module
for FILE in custom.app_replace_list.txt custom.pif.json custom.pif.prop skipdelprop skipmatchdevice skippersistprop; do
    if [ -f "/data/adb/modules/playintegrityfix/$FILE" ]; then
        ui_print "- Restoring $FILE"
        cp -af /data/adb/modules/playintegrityfix/$FILE $MODPATH/$FILE
    fi
done

# Keep persist prop restore commands, but not Integrity Box's own uninstall script
if [ -f /data/adb/modules/playintegrityfix/uninstall.sh ]; then
    grep '^resetprop' /data/adb/modules/playintegrityfix/uninstall.sh >> $MODPATH/uninstall.sh
fi

# Drop settings only known to Integrity Box's PIF fork
[ -f $MODPATH/custom.pif.prop ] && sed -i '/^spoofPixel=/d; /^spoofApps=/d' $MODPATH/custom.pif.prop

# Remove Integrity Box's boot scripts
for FILE in .box_cleanup.sh hash.sh lineage.sh package.sh prop.sh shamiko.sh; do
    grep -qs Box-Brain /data/adb/service.d/$FILE && rm -f /data/adb/service.d/$FILE
done

# Warn if potentially conflicting modules are installed
if [ -d /data/adb/modules/MagiskHidePropsConf ]; then
    ui_print "! MagiskHidePropsConfig (MHPC) module may cause issues with PIF"
fi

# Run common tasks for installation and boot-time
if [ -d "$MODPATH/zygisk" ]; then
    . $MODPATH/common_func.sh
    . $MODPATH/common_setup.sh
fi

# Migrate custom.pif.json to latest defaults if needed
if [ -f "$MODPATH/custom.pif.json" ]; then
    if ! grep -q "api_level" $MODPATH/custom.pif.json || ! grep -q "verboseLogs" $MODPATH/custom.pif.json || ! grep -q "spoofVendingFinger" $MODPATH/custom.pif.json; then
        ui_print "- Running migration script on custom.pif.json:"
        ui_print " "
        chmod 755 $MODPATH/migrate.sh
        sh $MODPATH/migrate.sh --install --force --advanced $MODPATH/custom.pif.json
        ui_print " "
    fi
fi

# Clean up any leftover files from previous deprecated methods
rm -f /data/data/com.google.android.gms/cache/pif.prop /data/data/com.google.android.gms/pif.prop \
    /data/data/com.google.android.gms/cache/pif.json /data/data/com.google.android.gms/pif.json

if [ ! -f /data/adb/tricky_store/keybox.xml ] || [ ! -f $MODPATH/custom.pif.prop -a ! -f $MODPATH/custom.pif.json ]; then
    ui_print "- Run the module Action after reboot to set up the keybox and fingerprint"
fi
