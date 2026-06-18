#!/bin/bash
set -e

SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
source "$SCRIPT_DIR/common.sh"
set_keys
VERSION_ARGS="$SCRIPT_DIR/vanadium/args.gn"
if [ ! -f "$VERSION_ARGS" ]; then
    echo "Missing $VERSION_ARGS. Run: git submodule update --init --recursive" >&2
    exit 1
fi
export VERSION=$(grep -m1 -o '[0-9]\+\(\.[0-9]\+\)\{3\}' "$VERSION_ARGS" || true)
if [ -z "$VERSION" ]; then
    echo "Unable to read Chromium version from $VERSION_ARGS" >&2
    exit 1
fi
export CHROMIUM_SOURCE=https://chromium.googlesource.com/chromium/src.git # https://github.com/chromium/chromium.git
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y sudo lsb-release file nano git curl python3 python3-pillow imagemagick ccache zstd bzip2
git config --global user.name "Helium CI"
git config --global user.email "helium-ci@localhost"

append_common_gn_args() {
    if command -v ccache >/dev/null 2>&1; then
        echo 'cc_wrapper = "ccache"' >> "$1"
    fi
}

restore_build_state() {
    if [ -n "$BUILD_STATE_ARCHIVE" ] && [ -f "$BUILD_STATE_ARCHIVE" ]; then
        echo "Restoring Chromium build state from $BUILD_STATE_ARCHIVE"
        tar -xf "$BUILD_STATE_ARCHIVE" -C .
        du -sh out/arm out/arm64 out/tmp 2>/dev/null || true
        export BUILD_STATE_RESTORED=1
    fi
}

refresh_restored_outputs() {
    if [ "${BUILD_STATE_RESTORED:-0}" = "1" ] && [ -d "$1" ]; then
        find "$1" -exec touch -h {} +
    fi
}

show_out_dir_state() {
    local out_dir="$1"

    if [ -d "$out_dir" ]; then
        echo "Build state for $out_dir:"
        ls -lh "$out_dir"/args.gn "$out_dir"/build.ninja "$out_dir"/.ninja_log "$out_dir"/.ninja_deps 2>/dev/null || true
    fi
}

configure_out_dir() {
    local out_dir="$1"
    local target_cpu="$2"
    local desired_args

    mkdir -p "$out_dir"
    desired_args="$(mktemp)"
    cp "$SCRIPT_DIR/args.gn" "$desired_args"
    if [ "$target_cpu" = "arm64" ]; then
        sed -i 's/target_cpu = "arm"/target_cpu = "arm64"/' "$desired_args"
    fi
    append_common_gn_args "$desired_args"

    if [ "${BUILD_STATE_RESTORED:-0}" = "1" ] && [ -f "$out_dir/build.ninja" ] && cmp -s "$desired_args" "$out_dir/args.gn"; then
        echo "Reusing restored GN output in $out_dir"
        rm -f "$desired_args"
        refresh_restored_outputs "$out_dir"
        show_out_dir_state "$out_dir"
        return
    fi

    mv "$desired_args" "$out_dir/args.gn"
    gn gen "$out_dir"
    refresh_restored_outputs "$out_dir"
    show_out_dir_state "$out_dir"
}

copy_first_output() {
    local search_dir="$1"
    local name_pattern="$2"
    local destination="$3"
    local output

    output="$(find "$search_dir" -name "$name_pattern" | head -n 1)"
    test -n "$output"
    cp "$output" "$destination"
}

# https://github.com/uazo/cromite/blob/master/tools/images/chr-source/prepare-build.sh
if [ ! -d depot_tools/.git ]; then
    git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
else
    git -C depot_tools fetch --depth 1 origin
    git -C depot_tools reset --hard origin/HEAD
fi
export PATH="$PWD/depot_tools:$PATH"
mkdir -p chromium/src
cd chromium/src
git init
git config user.name "Helium CI"
git config user.email "helium-ci@localhost"
if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin $CHROMIUM_SOURCE
else
    git remote set-url origin $CHROMIUM_SOURCE
fi
git fetch --depth 1 $CHROMIUM_SOURCE +refs/tags/$VERSION:chromium_$VERSION
git checkout $VERSION
export COMMIT=$(git show-ref -s $VERSION | head -n1)
cat > ../.gclient <<EOF
solutions = [
  {
    "name": "src",
    "url": "$CHROMIUM_SOURCE@$COMMIT",
    "deps_file": "DEPS",
    "managed": False,
    "custom_vars": {
      "checkout_android_prebuilts_build_tools": True,
      "checkout_telemetry_dependencies": False,
      "codesearch": "Debug",
    },
  },
]
target_os = ["android"]
EOF
git submodule foreach git config -f ./.git/config submodule.$name.ignore all
git config --add remote.origin.fetch '+refs/tags/*:refs/tags/*'

# https://grapheneos.org/build#browser-and-webview
rm -rf $SCRIPT_DIR/vanadium/patches/*trichrome-{apk-build-targets,browser-apk-targets}.patch
rm -rf $SCRIPT_DIR/vanadium/patches/*{detailed,supported}-language*.patch
rm -rf $SCRIPT_DIR/vanadium/patches/*component-updates.patch
# rm -rf $SCRIPT_DIR/vanadium/patches/*crashpad*.patch
replace "$SCRIPT_DIR/vanadium/patches" "VANADIUM" "HELIUM"
replace "$SCRIPT_DIR/vanadium/patches" "Vanadium" "Helium"
replace "$SCRIPT_DIR/vanadium/patches" "vanadium" "helium"
git am --whitespace=nowarn --keep-non-patch $SCRIPT_DIR/vanadium/patches/*.patch

cd ..
gclient sync -D --no-history --nohooks
gclient runhooks
cd src
rm -rf third_party/angle/third_party/VK-GL-CTS/
./build/install-build-deps.sh --no-prompt

# https://github.com/imputnet/helium-linux/blob/main/scripts/shared.sh
# python3 "${SCRIPT_DIR}/helium/utils/name_substitution.py" --sub -t .
# python3 "${SCRIPT_DIR}/helium/utils/helium_version.py" --tree "${SCRIPT_DIR}/helium" --chromium-tree .
# python3 "${SCRIPT_DIR}/helium/utils/generate_resources.py" "${SCRIPT_DIR}/helium/resources/generate_resources.txt" "${SCRIPT_DIR}/helium/resources"
# python3 "${SCRIPT_DIR}/helium/utils/replace_resources.py" "${SCRIPT_DIR}/helium/resources/helium_resources.txt" "${SCRIPT_DIR}/helium/resources" .

source $SCRIPT_DIR/patch.sh
restore_build_state

sudo dpkg --add-architecture i386; sudo apt-get update; sudo apt-get install -y libgcc-s1:i386
mkdir -p out/tmp out/release

configure_out_dir out/arm arm
autoninja -C out/arm chrome_public_apk
copy_first_output out/arm/apks 'Chrome*.apk' "out/tmp/$VERSION-armeabi-v7a.apk"

configure_out_dir out/arm64 arm64
autoninja -C out/arm64 chrome_public_apk chrome_public_bundle
copy_first_output out/arm64/apks 'Chrome*.apk' "out/tmp/$VERSION-arm64-v8a.apk"
copy_first_output out/arm64/apks 'Chrome*.aab' "out/tmp/$VERSION-arm64-v8a.aab"

export PATH=$PWD/third_party/jdk/current/bin/:$PATH
export ANDROID_HOME=$PWD/third_party/android_sdk/public
sign_apk out/tmp/$VERSION-armeabi-v7a.apk out/release/$VERSION-armeabi-v7a.apk
sign_apk out/tmp/$VERSION-arm64-v8a.apk out/release/$VERSION-arm64-v8a.apk
sign_aab out/tmp/$VERSION-arm64-v8a.aab out/release/$VERSION-arm64-v8a.aab
rm -rf $SCRIPT_DIR/keys
