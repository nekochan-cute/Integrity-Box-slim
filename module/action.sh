MODPATH="${0%/*}"
BOX=/data/adb/Box-Brain
TS=/data/adb/tricky_store
KEYBOX_URL=https://github.com/MeowDump/Integrity-Box/releases/download/archive/Megatron

# ensure not running in busybox ash standalone shell
if [ -n "$ASH_STANDALONE" ]; then
    set +o standalone
    unset ASH_STANDALONE
fi

TMP=$(mktemp -d /data/local/tmp/ibslim.XXXXXX) || exit 1
trap "rm -rf $TMP" EXIT
mkdir -p $TS
RC=0

download() {
    curl -fsL -o "$2" "$1" 2>/dev/null && return
    for BB in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
        [ -x $BB ] && $BB wget -q -T 15 -O "$2" "$1" && return
    done
    return 1
}

if [ -f $BOX/keep-keybox ]; then
    echo "- Keeping current keybox"
elif ! download $KEYBOX_URL $TMP/keybox; then
    echo "! Keybox download failed"
    RC=1
else
    # base64 encoded 10 times, then hex and ROT13 with filler words
    for i in 1 2 3 4 5 6 7 8 9 10; do
        base64 -d $TMP/keybox > $TMP/keybox.b64 && mv -f $TMP/keybox.b64 $TMP/keybox
    done
    xxd -r -p $TMP/keybox | tr A-Za-z N-ZA-Mn-za-m | sed -E 's/aristotle|socrates|plato|confucius//g' > $TMP/keybox.xml

    if ! grep -q '</AndroidAttestation>' $TMP/keybox.xml || ! grep -q 'BEGIN CERTIFICATE' $TMP/keybox.xml; then
        echo "! Downloaded keybox is invalid, keeping current one"
        RC=1
    elif cmp -s $TMP/keybox.xml $TS/keybox.xml; then
        echo "- Keybox is up to date"
    else
        [ -f $TS/keybox.xml.bak ] || cp -f $TS/keybox.xml $TS/keybox.xml.bak 2>/dev/null
        cp -f $TMP/keybox.xml $TS/keybox.xml
        # keys generated with the old keybox
        rm -rf $TS/key_db/* $TS/persistent_keys/*
        echo "- Keybox updated"
    fi
fi

grep -q '^teeBroken=true' $TS/tee_status 2>/dev/null && SUFFIX="!"
{
    printf '%s\n' com.android.vending com.google.android.gms com.google.android.gsf \
        com.google.android.apps.walletnfcrel com.google.android.apps.messaging \
        io.github.vvb2060.keyattestation io.github.qwq233.keyattestation
    pm list packages -3 | cut -d: -f2
} | sort -u > $TMP/target.txt
if [ -f $BOX/blacklist.txt ]; then
    sed 's/[[:space:]]//g; /^$/d' $BOX/blacklist.txt > $TMP/blacklist.txt
    grep -vxFf $TMP/blacklist.txt $TMP/target.txt > $TMP/target.new
    mv -f $TMP/target.new $TMP/target.txt
fi
[ -f $TS/target.txt.bak ] || cp -f $TS/target.txt $TS/target.txt.bak 2>/dev/null
sed "s/\$/$SUFFIX/" $TMP/target.txt > $TS/target.txt
echo "- Added $(wc -l < $TS/target.txt) apps to target.txt"

if [ -f $MODPATH/autopif4.sh ]; then
    [ -f $MODPATH/skipmatchdevice ] || MATCHFLAG=-m
    sh $MODPATH/autopif4.sh $MATCHFLAG || RC=1
fi
sh "$MODPATH/integrity_setup.sh" || RC=1
sh "$MODPATH/killpi.sh"

[ $RC -eq 0 ] && echo -e "\nDone!"

# warn since KernelSU/APatch's implementation automatically closes if successful
if [ "$KSU" = "true" -o "$APATCH" = "true" ] && [ "$KSU_NEXT" != "true" ] && [ "$KSU_SUKISU" != "true" ] && [ "$WKSU" != "true" ] && [ "$MMRL" != "true" ]; then
    echo -e "\nClosing dialog in 20 seconds ..."
    sleep 20
fi
exit $RC
