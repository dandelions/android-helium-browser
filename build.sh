#!/bin/bash
set -e

SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
source "$SCRIPT_DIR/common.sh"
cd "$SCRIPT_DIR"
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
BUILD_ARM="${BUILD_ARM:-0}"
BUILD_ARM64="${BUILD_ARM64:-1}"
BUILD_AAB="${BUILD_AAB:-0}"
NINJA_JOBS="${NINJA_JOBS:-14}"
BUILD_VERSION_INCREMENT="${BUILD_VERSION_INCREMENT:-$((($(date -u +%s) - 1577836800) / 60))}"
if [ "$BUILD_ARM" != "1" ] && [ "$BUILD_ARM64" != "1" ]; then
    echo "At least one target ABI must be enabled. Set BUILD_ARM=1 or BUILD_ARM64=1." >&2
    exit 1
fi
if [ "$BUILD_AAB" = "1" ] && [ "$BUILD_ARM64" != "1" ]; then
    echo "BUILD_AAB=1 requires BUILD_ARM64=1." >&2
    exit 1
fi
case "$BUILD_VERSION_INCREMENT" in
    ''|*[!0-9]*)
        echo "BUILD_VERSION_INCREMENT must be a non-negative integer." >&2
        exit 1
        ;;
esac
if [ "$BUILD_VERSION_INCREMENT" -gt 13000000 ]; then
    echo "BUILD_VERSION_INCREMENT=$BUILD_VERSION_INCREMENT is too large for Chromium Android versionCode." >&2
    exit 1
fi
export CHROMIUM_SOURCE=https://chromium.googlesource.com/chromium/src.git # https://github.com/chromium/chromium.git
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y sudo lsb-release file nano git curl python3 python3-pillow imagemagick ccache zstd bzip2 openjdk-17-jre-headless
set_keys
git config --global user.name "Helium CI"
git config --global user.email "helium-ci@localhost"

append_common_gn_args() {
    if command -v ccache >/dev/null 2>&1; then
        echo 'cc_wrapper = "ccache"' >> "$1"
    fi
}

set_gn_arg() {
    local file="$1"
    local name="$2"
    local value="$3"

    if grep -q "^${name}[[:space:]]*=" "$file"; then
        sed -i "s|^${name}[[:space:]]*=.*|${name} = ${value}|" "$file"
    else
        printf '%s = %s\n' "$name" "$value" >> "$file"
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
    set_gn_arg "$desired_args" ext_version_enabled true
    set_gn_arg "$desired_args" ext_version_increment "\"$BUILD_VERSION_INCREMENT\""
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

run_autoninja() {
    local out_dir="$1"
    shift

    if [ -n "${NINJA_JOBS:-}" ]; then
        autoninja -C "$out_dir" -j "$NINJA_JOBS" "$@"
    else
        autoninja -C "$out_dir" "$@"
    fi
}

reset_chromium_checkout() {
    git am --abort >/dev/null 2>&1 || true
    git rebase --abort >/dev/null 2>&1 || true
    git merge --abort >/dev/null 2>&1 || true

    if git rev-parse --verify HEAD >/dev/null 2>&1; then
        git reset --hard
        git clean -fd -e out/
    fi
}

reset_chromium_submodules() {
    git submodule foreach --recursive '
        git am --abort >/dev/null 2>&1 || true
        git rebase --abort >/dev/null 2>&1 || true
        git merge --abort >/dev/null 2>&1 || true
        git_dir=$(git rev-parse --git-dir 2>/dev/null || true)
        if [ -n "$git_dir" ]; then
            rm -rf "$git_dir/rebase-apply" "$git_dir/rebase-merge"
        fi
        git reset --hard >/dev/null 2>&1 || true
        git clean -fd -e out/ >/dev/null 2>&1 || true
    '
}

ensure_depot_tools_bootstrap() {
    export DEPOT_TOOLS_DIR="$SCRIPT_DIR/depot_tools"
    "$DEPOT_TOOLS_DIR/ensure_bootstrap"

    if [ ! -f "$DEPOT_TOOLS_DIR/python3_bin_reldir.txt" ]; then
        echo "depot_tools bootstrap failed: missing $DEPOT_TOOLS_DIR/python3_bin_reldir.txt" >&2
        exit 1
    fi
}

patch_filter_list_downloader() {
    local downloader="helium/android_config/filter_lists/filter_list_download.py"
    if [ ! -f "$downloader" ]; then
        return
    fi

    cat > "$downloader" <<'PY'
#!/usr/bin/env python3
#
# SPDX-License-Identifier: GPL-v2.0

import argparse
import hashlib
import os
import ssl
import sys
import time
import urllib.error
import urllib.request

FALLBACK_URLS = {
    'https://abpvn.com/filter/abpvn-IPl6HE.txt': [
        'https://raw.githubusercontent.com/abpvn/abpvn/master/filter/abpvn.txt',
    ],
}


def IsOptionalList(output):
    name = os.path.basename(output)
    return name.startswith('filter_lists_easylist_') and name != 'filter_lists_easylist.txt'


def FetchUrl(url, retries=5):
    context = ssl.create_default_context(ssl.Purpose.SERVER_AUTH)
    context.minimum_version = ssl.TLSVersion.TLSv1_2
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    last_error = None

    for attempt in range(1, retries + 1):
        try:
            chunks = []
            with urllib.request.urlopen(url=req, context=context, timeout=120) as res:
                while True:
                    buf = res.read(65536)
                    if not buf:
                        return b''.join(chunks)
                    chunks.append(buf)
        except Exception as exc:
            last_error = exc
            print(f'warning: failed to fetch {url} on attempt {attempt}/{retries}: {exc}', file=sys.stderr)
            if attempt != retries:
                time.sleep(min(30, attempt * 5))

    raise last_error


def FetchWithFallbacks(url):
    errors = []
    for candidate in [url] + FALLBACK_URLS.get(url, []):
        try:
            return FetchUrl(candidate)
        except Exception as exc:
            errors.append(f'{candidate}: {exc}')
    raise RuntimeError('; '.join(errors))


def FetchAndGenerateFilterList(args):
    urls = sorted(list(set(args.urls)))
    output = args.output
    hasher = hashlib.new('sha256')

    os.makedirs(os.path.dirname(output), exist_ok=True)
    with open(output, 'wb') as output_file:
        for url in urls:
            if not url.startswith('https://'):
                continue
            try:
                data = FetchWithFallbacks(url)
            except Exception as exc:
                if IsOptionalList(output):
                    print(f'warning: skipping optional filter list URL {url}: {exc}', file=sys.stderr)
                    continue
                raise
            output_file.write(data)
            hasher.update(data)

    with open('.'.join([output, 'sha256']), 'w') as f:
        f.write(hasher.hexdigest())


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--urls', nargs='+',
                        help='URLs to download for the generated filter list.')
    parser.add_argument('--output', required=True)
    FetchAndGenerateFilterList(parser.parse_args(sys.argv[1:]))
PY
}

# https://github.com/uazo/cromite/blob/master/tools/images/chr-source/prepare-build.sh
if [ ! -d depot_tools/.git ]; then
    git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
else
    git -C depot_tools fetch --depth 1 origin
    git -C depot_tools reset --hard origin/HEAD
fi
export PATH="$PWD/depot_tools:$PATH"
ensure_depot_tools_bootstrap
mkdir -p chromium/src
cd chromium/src
git init
git config user.name "Helium CI"
git config user.email "helium-ci@localhost"
reset_chromium_checkout
if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin $CHROMIUM_SOURCE
else
    git remote set-url origin $CHROMIUM_SOURCE
fi
git fetch --depth 1 $CHROMIUM_SOURCE +refs/tags/$VERSION:chromium_$VERSION
git checkout -f $VERSION
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
reset_chromium_submodules

# https://grapheneos.org/build#browser-and-webview
rm -rf $SCRIPT_DIR/vanadium/patches/*trichrome-{apk-build-targets,browser-apk-targets}.patch
rm -rf $SCRIPT_DIR/vanadium/patches/*{detailed,supported}-language*.patch
rm -rf $SCRIPT_DIR/vanadium/patches/*component-updates.patch
# rm -rf $SCRIPT_DIR/vanadium/patches/*crashpad*.patch
replace "$SCRIPT_DIR/vanadium/patches" "VANADIUM" "HELIUM"
replace "$SCRIPT_DIR/vanadium/patches" "Vanadium" "Helium"
replace "$SCRIPT_DIR/vanadium/patches" "vanadium" "helium"
git am --whitespace=nowarn --keep-non-patch $SCRIPT_DIR/vanadium/patches/*.patch
patch_filter_list_downloader

cd ..
gclient sync -D --no-history --nohooks
cd src
reset_chromium_submodules
cd ..
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
echo "Build options: BUILD_ARM=$BUILD_ARM BUILD_ARM64=$BUILD_ARM64 BUILD_AAB=$BUILD_AAB BUILD_VERSION_INCREMENT=$BUILD_VERSION_INCREMENT NINJA_JOBS=${NINJA_JOBS:-auto}"

if [ "$BUILD_ARM" = "1" ]; then
    configure_out_dir out/arm arm
    run_autoninja out/arm chrome_public_apk
    copy_first_output out/arm/apks 'Chrome*.apk' "out/tmp/$VERSION-armeabi-v7a.apk"
fi

if [ "$BUILD_ARM64" = "1" ]; then
    configure_out_dir out/arm64 arm64
    arm64_targets="chrome_public_apk"
    if [ "$BUILD_AAB" = "1" ]; then
        arm64_targets="$arm64_targets chrome_public_bundle"
    fi
    run_autoninja out/arm64 $arm64_targets
    copy_first_output out/arm64/apks 'Chrome*.apk' "out/tmp/$VERSION-arm64-v8a.apk"
    if [ "$BUILD_AAB" = "1" ]; then
        copy_first_output out/arm64/apks 'Chrome*.aab' "out/tmp/$VERSION-arm64-v8a.aab"
    fi
fi

export PATH=$PWD/third_party/jdk/current/bin/:$PATH
export ANDROID_HOME=$PWD/third_party/android_sdk/public
release_outputs=""
if [ "$BUILD_ARM" = "1" ]; then
    sign_apk out/tmp/$VERSION-armeabi-v7a.apk out/release/$VERSION-armeabi-v7a.apk
    release_outputs="$release_outputs out/release/$VERSION-armeabi-v7a.apk"
fi
if [ "$BUILD_ARM64" = "1" ]; then
    sign_apk out/tmp/$VERSION-arm64-v8a.apk out/release/$VERSION-arm64-v8a.apk
    release_outputs="$release_outputs out/release/$VERSION-arm64-v8a.apk"
    if [ "$BUILD_AAB" = "1" ]; then
        sign_aab out/tmp/$VERSION-arm64-v8a.aab out/release/$VERSION-arm64-v8a.aab
        release_outputs="$release_outputs out/release/$VERSION-arm64-v8a.aab"
    fi
fi
echo "Build outputs:"
ls -lh $release_outputs
