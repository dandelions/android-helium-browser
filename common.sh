export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

replace() {
    export org=$2 new=$3
    find $1 -type f -exec sed -i 's@'$org'@'$new'@g' {} \;
}

generate_test_keys() {
    rm -f "$SCRIPT_DIR/keys/local.properties" "$SCRIPT_DIR/keys/test.jks"

    cat > "$SCRIPT_DIR/keys/local.properties" <<'EOF'
keyAlias=helium-ci
keyPassword=android
storePassword=android
storeType=PKCS12
EOF

    keytool -genkeypair \
        -storetype PKCS12 \
        -keystore "$SCRIPT_DIR/keys/test.jks" \
        -storepass android \
        -keypass android \
        -alias helium-ci \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -dname "CN=Helium CI,O=Helium,C=US"
}

validate_keys() {
    source "$SCRIPT_DIR/keys/local.properties"
    if [ -n "${storeType:-}" ]; then
        keytool -list -storetype "$storeType" -keystore "$SCRIPT_DIR/keys/test.jks" -storepass "$storePassword" -alias "$keyAlias" >/dev/null
    else
        keytool -list -keystore "$SCRIPT_DIR/keys/test.jks" -storepass "$storePassword" -alias "$keyAlias" >/dev/null
    fi
}

set_keys() {
    mkdir -p "$SCRIPT_DIR/keys"
    if [ -n "${LOCAL_TEST_JKS:-}" ] && [ -n "${STORE_TEST_JKS:-}" ]; then
        printf '%s' "$LOCAL_TEST_JKS" | base64 -d > "$SCRIPT_DIR/keys/local.properties"
        printf '%s' "$STORE_TEST_JKS" | base64 -d > "$SCRIPT_DIR/keys/test.jks"
    elif [ -s "$SCRIPT_DIR/keys/local.properties" ] && [ -s "$SCRIPT_DIR/keys/test.jks" ]; then
        echo "Reusing existing local signing key from $SCRIPT_DIR/keys."
    else
        echo "Signing config was not provided; generating a local test signing key."
        generate_test_keys
    fi
    validate_keys
    unset LOCAL_TEST_JKS
    unset STORE_TEST_JKS
}

sign_apk() {
    local apksigner
    local zipalign
    local aligned_apk

    apksigner=$(find "$ANDROID_HOME/build-tools" -name apksigner | sort | tail -n 1)
    zipalign=$(find "$ANDROID_HOME/build-tools" -name zipalign | sort | tail -n 1)
    if [ -z "$apksigner" ] || [ -z "$zipalign" ]; then
        echo "Missing Android build-tools apksigner or zipalign." >&2
        exit 1
    fi

    aligned_apk="$(mktemp --suffix=.apk)"
    "$zipalign" -f -p 4 "$1" "$aligned_apk"

    source "$SCRIPT_DIR/keys/local.properties"
    if [ -n "${storeType:-}" ]; then
        "$apksigner" sign --verbose \
            --v1-signing-enabled true \
            --v2-signing-enabled true \
            --v3-signing-enabled true \
            --v4-signing-enabled false \
            --ks "$SCRIPT_DIR/keys/test.jks" \
            --ks-type "$storeType" \
            --ks-pass "pass:$storePassword" \
            --key-pass "pass:$keyPassword" \
            --ks-key-alias "$keyAlias" \
            --out "$2" \
            "$aligned_apk" || exit 1
    else
        "$apksigner" sign --verbose \
            --v1-signing-enabled true \
            --v2-signing-enabled true \
            --v3-signing-enabled true \
            --v4-signing-enabled false \
            --ks "$SCRIPT_DIR/keys/test.jks" \
            --ks-pass "pass:$storePassword" \
            --key-pass "pass:$keyPassword" \
            --ks-key-alias "$keyAlias" \
            --out "$2" \
            "$aligned_apk" || exit 1
    fi

    "$apksigner" verify --verbose "$2" || exit 1
    rm -f "$aligned_apk"
}

sign_aab() {
    source "$SCRIPT_DIR/keys/local.properties"
    if [ -n "${storeType:-}" ]; then
        jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
            -storetype "$storeType" \
            -keystore "$SCRIPT_DIR/keys/test.jks" \
            -storepass "$storePassword" \
            -keypass "$keyPassword" \
            -signedjar "$2" "$1" "$keyAlias" || exit 1
    else
        jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
            -keystore "$SCRIPT_DIR/keys/test.jks" \
            -storepass "$storePassword" \
            -keypass "$keyPassword" \
            -signedjar "$2" "$1" "$keyAlias" || exit 1
    fi
}
