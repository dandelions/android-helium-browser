#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${1:-$SCRIPT_DIR/chromium/src}"

if [ ! -d "$SRC_DIR" ]; then
    echo "Chromium source directory not found: $SRC_DIR" >&2
    exit 1
fi

cd "$SRC_DIR"

BRIDGE=chrome/browser/ui/android/extensions/java/src/org/chromium/chrome/browser/ui/extensions/ExtensionsMenuBridge.java
MENU_MEDIATOR=chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
TOOLBAR=chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
CTA=chrome/android/java/src/org/chromium/chrome/browser/ChromeTabbedActivity.java
VERIFIER=chrome/browser/extensions/chrome_content_verifier_delegate.cc
PROFILE_INFO=chrome/browser/extensions/api/developer_private/profile_info_generator.cc
DEV_PRIVATE_FUNCTIONS=chrome/browser/extensions/api/developer_private/developer_private_functions.cc
TIMESTAMP_GNI=build/timestamp.gni
CONTENT_SETTINGS_FEATURES=components/content_settings/core/common/features.cc
APP_MENU_DELEGATE=chrome/android/java/src/org/chromium/chrome/browser/app/appmenu/AppMenuPropertiesDelegateImpl.java
MENU_DELEGATE_CC=chrome/browser/ui/android/extensions/extensions_menu_delegate_android.cc
MENU_DELEGATE_H=chrome/browser/ui/android/extensions/extensions_menu_delegate_android.h
ACTION_DELEGATE_CC=chrome/browser/ui/android/extensions/extension_action_delegate_android.cc
ZIP_INSTALLER=extensions/browser/zipfile_installer.cc
WEB_REQUEST_ROUTER=extensions/browser/api/web_request/extension_web_request_event_router.cc
TAB_STORE=chrome/android/java/src/org/chromium/chrome/browser/tabmodel/TabPersistentStoreImpl.java
JS_DIALOG_MANAGER=components/javascript_dialogs/app_modal_dialog_manager.cc
UNGOOGLED_FLAGS=chrome/browser/ungoogled_flag_entries.h
NAV_POLICY=content/renderer/render_frame_impl.cc
WINDOW_OPEN_TRAITS=ui/base/mojom/window_open_disposition_mojom_traits.h

for file in "$BRIDGE" "$MENU_MEDIATOR" "$TOOLBAR" "$CTA" "$VERIFIER" "$PROFILE_INFO" "$DEV_PRIVATE_FUNCTIONS" "$TIMESTAMP_GNI" "$CONTENT_SETTINGS_FEATURES" "$APP_MENU_DELEGATE" "$MENU_DELEGATE_CC" "$MENU_DELEGATE_H" "$ACTION_DELEGATE_CC" "$ZIP_INSTALLER" "$WEB_REQUEST_ROUTER" "$TAB_STORE" "$JS_DIALOG_MANAGER" "$NAV_POLICY" "$WINDOW_OPEN_TRAITS"; do
    if [ ! -f "$file" ]; then
        echo "Expected file not found: $SRC_DIR/$file" >&2
        exit 1
    fi
done

# Desktop-Android arm64 Chrome can pull in android_webview's arm64 toolchain
# during GN generation. Chromium's timestamp.gni only expected the default
# toolchain when secondary ABI is disabled, so allow this known Android WebView
# toolchain to import the timestamp as well.
perl -0pi -e 's|current_toolchain == default_toolchain,|current_toolchain == default_toolchain \|\|\n        current_toolchain == "//build/toolchain/android:android_clang_arm64_webview",|' "$TIMESTAMP_GNI"

# Keep the per-site darkening toggle visible. FAST_LOCAL_BUILD skips patch.sh,
# so mirror the normal patch here for existing Chromium source trees.
perl -0pi -e 's/BASE_FEATURE\(kDarkenWebsitesCheckboxInThemesSetting,\n\s*base::FEATURE_DISABLED_BY_DEFAULT\);/BASE_FEATURE(kDarkenWebsitesCheckboxInThemesSetting,\n             base::FEATURE_ENABLED_BY_DEFAULT);/' "$CONTENT_SETTINGS_FEATURES"
perl -0pi -e 's/return currentTab != null && !isNativePage && isFlagEnabled && isFeatureEnabled;/return currentTab != null && !isNativePage;/g; s/return currentTab != null[^\n]*isFeatureEnabled[^\n]*!isNativePage;/return currentTab != null && !isNativePage;/g' "$APP_MENU_DELEGATE"

# Always allow closing/replacing tabs without showing a page-provided
# beforeunload confirmation. This only affects beforeunload dialogs; normal
# JavaScript alert/confirm/prompt dialogs keep their existing behavior.
grep -q 'Helium: beforeunload dialogs are disabled by default' "$JS_DIALOG_MANAGER" || \
    sed -i '/void AppModalDialogManager::RunBeforeUnloadDialog(/,/^[}]$/ { /ChromeJavaScriptDialogExtraData\* extra_data =/i\
  // Helium: beforeunload dialogs are disabled by default.\
  std::move(callback).Run(true, std::u16string());\
  return;\

}' "$JS_DIALOG_MANAGER"

# Add a user-facing flag for sites that force links into new tabs/windows.
# Disabled by default; enable chrome://flags/#open-new-links-in-current-tab to
# make those navigations reuse the current tab.
if [ -f "$UNGOOGLED_FLAGS" ] && ! grep -q '"open-new-links-in-current-tab"' "$UNGOOGLED_FLAGS"; then
    sed -i '/SINGLE_VALUE_TYPE("popups-to-tabs")},/a\
    {"open-new-links-in-current-tab",\
     "Open new links in current tab",\
     "Forces site-requested new tabs and windows to navigate in the current tab. ungoogled-chromium flag",\
     kOsAll, SINGLE_VALUE_TYPE("open-new-links-in-current-tab")},' "$UNGOOGLED_FLAGS"
fi
grep -q '#include "base/command_line.h"' "$NAV_POLICY" || \
    sed -i '0,/^#include /s|^#include |#include "base/command_line.h"\n#include |' "$NAV_POLICY"
if ! grep -q 'open-new-links-in-current-tab' "$NAV_POLICY"; then
    sed -i '/case blink::kWebNavigationPolicyNewBackgroundTab:/,/return WindowOpenDisposition::NEW_BACKGROUND_TAB;/ s|return WindowOpenDisposition::NEW_BACKGROUND_TAB;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n        return WindowOpenDisposition::CURRENT_TAB;\n      return WindowOpenDisposition::NEW_BACKGROUND_TAB;|' "$NAV_POLICY"
    sed -i '/case blink::kWebNavigationPolicyNewForegroundTab:/,/return WindowOpenDisposition::NEW_FOREGROUND_TAB;/ s|return WindowOpenDisposition::NEW_FOREGROUND_TAB;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n        return WindowOpenDisposition::CURRENT_TAB;\n      return WindowOpenDisposition::NEW_FOREGROUND_TAB;|' "$NAV_POLICY"
    sed -i '/case blink::kWebNavigationPolicyNewWindow:/,/return WindowOpenDisposition::NEW_WINDOW;/ s|return WindowOpenDisposition::NEW_WINDOW;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n        return WindowOpenDisposition::CURRENT_TAB;\n      return WindowOpenDisposition::NEW_WINDOW;|' "$NAV_POLICY"
    sed -i '/case blink::kWebNavigationPolicyNewPopup:/,/return WindowOpenDisposition::NEW_POPUP;/ s|return WindowOpenDisposition::NEW_POPUP;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n        return WindowOpenDisposition::CURRENT_TAB;\n      return WindowOpenDisposition::NEW_POPUP;|' "$NAV_POLICY"
fi
grep -q '#include "base/command_line.h"' "$WINDOW_OPEN_TRAITS" || \
    sed -i '0,/^#include /s|^#include |#include "base/command_line.h"\n#include |' "$WINDOW_OPEN_TRAITS"
if ! grep -q 'open-new-links-in-current-tab' "$WINDOW_OPEN_TRAITS"; then
    sed -i '/case WindowOpenDisposition::NEW_FOREGROUND_TAB:/,/return ui::mojom::WindowOpenDisposition::NEW_FOREGROUND_TAB;/ s|return ui::mojom::WindowOpenDisposition::NEW_FOREGROUND_TAB;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return ui::mojom::WindowOpenDisposition::CURRENT_TAB;\n        return ui::mojom::WindowOpenDisposition::NEW_FOREGROUND_TAB;|' "$WINDOW_OPEN_TRAITS"
    sed -i '/case WindowOpenDisposition::NEW_BACKGROUND_TAB:/,/return ui::mojom::WindowOpenDisposition::NEW_BACKGROUND_TAB;/ s|return ui::mojom::WindowOpenDisposition::NEW_BACKGROUND_TAB;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return ui::mojom::WindowOpenDisposition::CURRENT_TAB;\n        return ui::mojom::WindowOpenDisposition::NEW_BACKGROUND_TAB;|' "$WINDOW_OPEN_TRAITS"
    sed -i '/case WindowOpenDisposition::NEW_POPUP:/,/return ui::mojom::WindowOpenDisposition::NEW_POPUP;/ s|return ui::mojom::WindowOpenDisposition::NEW_POPUP;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return ui::mojom::WindowOpenDisposition::CURRENT_TAB;\n        return ui::mojom::WindowOpenDisposition::NEW_POPUP;|' "$WINDOW_OPEN_TRAITS"
    sed -i '/case WindowOpenDisposition::NEW_WINDOW:/,/return ui::mojom::WindowOpenDisposition::NEW_WINDOW;/ s|return ui::mojom::WindowOpenDisposition::NEW_WINDOW;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return ui::mojom::WindowOpenDisposition::CURRENT_TAB;\n        return ui::mojom::WindowOpenDisposition::NEW_WINDOW;|' "$WINDOW_OPEN_TRAITS"
    sed -i '/case ui::mojom::WindowOpenDisposition::NEW_FOREGROUND_TAB:/,/return WindowOpenDisposition::NEW_FOREGROUND_TAB;/ s|return WindowOpenDisposition::NEW_FOREGROUND_TAB;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return WindowOpenDisposition::CURRENT_TAB;\n        return WindowOpenDisposition::NEW_FOREGROUND_TAB;|' "$WINDOW_OPEN_TRAITS"
    sed -i '/case ui::mojom::WindowOpenDisposition::NEW_BACKGROUND_TAB:/,/return WindowOpenDisposition::NEW_BACKGROUND_TAB;/ s|return WindowOpenDisposition::NEW_BACKGROUND_TAB;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return WindowOpenDisposition::CURRENT_TAB;\n        return WindowOpenDisposition::NEW_BACKGROUND_TAB;|' "$WINDOW_OPEN_TRAITS"
    sed -i '/case ui::mojom::WindowOpenDisposition::NEW_POPUP:/,/return WindowOpenDisposition::NEW_POPUP;/ s|return WindowOpenDisposition::NEW_POPUP;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return WindowOpenDisposition::CURRENT_TAB;\n        return WindowOpenDisposition::NEW_POPUP;|' "$WINDOW_OPEN_TRAITS"
    sed -i '/case ui::mojom::WindowOpenDisposition::NEW_WINDOW:/,/return WindowOpenDisposition::NEW_WINDOW;/ s|return WindowOpenDisposition::NEW_WINDOW;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return WindowOpenDisposition::CURRENT_TAB;\n        return WindowOpenDisposition::NEW_WINDOW;|' "$WINDOW_OPEN_TRAITS"
    sed -i '/case ui::mojom::WindowOpenDisposition::NEW_FOREGROUND_TAB:/,/return true;/ s|return true;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          *out = WindowOpenDisposition::CURRENT_TAB;\n        return true;|' "$WINDOW_OPEN_TRAITS"
    sed -i '/case ui::mojom::WindowOpenDisposition::NEW_BACKGROUND_TAB:/,/return true;/ s|return true;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          *out = WindowOpenDisposition::CURRENT_TAB;\n        return true;|' "$WINDOW_OPEN_TRAITS"
    sed -i '/case ui::mojom::WindowOpenDisposition::NEW_POPUP:/,/return true;/ s|return true;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          *out = WindowOpenDisposition::CURRENT_TAB;\n        return true;|' "$WINDOW_OPEN_TRAITS"
    sed -i '/case ui::mojom::WindowOpenDisposition::NEW_WINDOW:/,/return true;/ s|return true;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          *out = WindowOpenDisposition::CURRENT_TAB;\n        return true;|' "$WINDOW_OPEN_TRAITS"
fi

# Repair a bad intermediate JNI annotation generated by an older patch.
sed -i 's|                ("std::string") String extensionId);|                @JniType("std::string") String extensionId);|' "$BRIDGE"

# Do not call the native options-page path from the Android extensions menu.
# It can crash on Android browser-window contexts. Route primary menu clicks
# through the toolbar bridge, which pops out an anchor button before showing
# extension popups.
perl -0pi -e 's|\n        if \(mMenuBridge\.openOptionsPage\(extensionId\)\) \{\n            return;\n        \}\n||' "$MENU_MEDIATOR"
grep -q 'org.chromium.chrome.browser.ui.toolbar.InvocationSource' "$MENU_MEDIATOR" || \
    sed -i '/import org.chromium.chrome.browser.ui.extensions.ExtensionsToolbarBridge;/a\import org.chromium.chrome.browser.ui.toolbar.InvocationSource;' "$MENU_MEDIATOR"
grep -q 'ExtensionsToolbarBridge mToolbarBridge;' "$MENU_MEDIATOR" || \
    sed -i '/private final ExtensionsMenuBridge mMenuBridge;/a\    private ExtensionsToolbarBridge mToolbarBridge;' "$MENU_MEDIATOR"
sed -i 's|private final ExtensionsToolbarBridge mToolbarBridge;|private ExtensionsToolbarBridge mToolbarBridge;|' "$MENU_MEDIATOR"
grep -q 'mToolbarBridge = toolbarBridge;' "$MENU_MEDIATOR" || \
    perl -0pi -e 's|(\n[ \t]*)(mMenuBridge[ \t]*=)|$1mToolbarBridge = toolbarBridge;\n$1$2|' "$MENU_MEDIATOR"
sed -i 's|(view) -> openExtensionFromMenu(entry.id))|(view) -> mMenuBridge.executeAction(entry.id))|' "$MENU_MEDIATOR"
sed -i 's|(view) -> openUrlFromMenu(UrlConstants.CHROME_EXTENSIONS_ID_URL + entry.id))|(view) -> mMenuBridge.executeAction(entry.id))|' "$MENU_MEDIATOR"
sed -i 's|(view) -> mMenuBridge.executeAction(entry.id))|(view) -> mToolbarBridge.executeUserAction(entry.id, InvocationSource.TOOLBAR_BUTTON))|' "$MENU_MEDIATOR"
sed -i 's|(view) -> mToolbarBridge.executeUserAction(entry.id, InvocationSource.TOOLBAR_BUTTON))|(view) -> openExtensionOptionsFromMenu(entry.id))|' "$MENU_MEDIATOR"
grep -q 'private void openExtensionOptionsFromMenu' "$MENU_MEDIATOR" || \
    sed -i '/private void openUrlFromMenu(String url) {/i\
    private void openExtensionOptionsFromMenu(String extensionId) {\
        String optionsUrl = mMenuBridge.getOptionsPageUrl(extensionId);\
        if (optionsUrl != null && !optionsUrl.isEmpty()) {\
            openUrlFromMenu(optionsUrl);\
            return;\
        }\
        if (mToolbarBridge != null) {\
            mToolbarBridge.executeUserAction(extensionId, InvocationSource.TOOLBAR_BUTTON);\
            return;\
        }\
        mMenuBridge.executeAction(extensionId);\
    }\
' "$MENU_MEDIATOR"
grep -q 'getOptionsPageUrl(String extensionId)' "$BRIDGE" || \
    sed -i '/public void executeAction(String extensionId) {/i\
    public String getOptionsPageUrl(String extensionId) {\
        return ExtensionsMenuBridgeJni.get()\
                .getOptionsPageUrl(mNativeExtensionsMenuDelegateAndroid, extensionId);\
    }\
' "$BRIDGE"
grep -q '^        String getOptionsPageUrl(' "$BRIDGE" || \
    perl -0pi -e 's|(\n\s*\@NativeMethods\n\s*public interface Natives \{\n)|$1        \@JniType("std::string")\n        String getOptionsPageUrl(\n                long nativeExtensionsMenuDelegateAndroid,\n                \@JniType("std::string") String extensionId);\n\n|' "$BRIDGE"
grep -q '#include <string>' "$MENU_DELEGATE_H" || \
    sed -i '/^#include "base\/android\/jni_android.h"/i\#include <string>' "$MENU_DELEGATE_H"
grep -q 'GetOptionsPageUrl(JNIEnv' "$MENU_DELEGATE_H" || \
    sed -i '/void ExecuteAction(JNIEnv\* env, const extensions::ExtensionId& extension_id);/a\  std::string GetOptionsPageUrl(JNIEnv* env, const std::string& extension_id);' "$MENU_DELEGATE_H"
grep -q 'extensions/common/manifest_handlers/options_page_info.h' "$MENU_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/ui\/android\/extensions\/extension_action_delegate_android.h"/a\#include "chrome/browser/profiles/profile.h"\n#include "extensions/browser/extension_registry.h"\n#include "extensions/common/manifest_handlers/options_page_info.h"' "$MENU_DELEGATE_CC"
grep -q 'ExtensionsMenuDelegateAndroid::GetOptionsPageUrl' "$MENU_DELEGATE_CC" || \
    sed -i '/void ExtensionsMenuDelegateAndroid::ExecuteAction(/i\
std::string ExtensionsMenuDelegateAndroid::GetOptionsPageUrl(\
    JNIEnv* env,\
    const std::string& extension_id) {\
  extensions::ExtensionRegistry* registry =\
      extensions::ExtensionRegistry::Get(browser_->GetProfile());\
  if (!registry) {\
    return std::string();\
  }\
  const extensions::Extension* extension =\
      registry->enabled_extensions().GetByID(extension_id);\
  if (!extension || !extensions::OptionsPageInfo::HasOptionsPage(extension)) {\
    return std::string();\
  }\
  const GURL& options_url =\
      extensions::OptionsPageInfo::GetOptionsPage(extension);\
  return options_url.is_valid() ? options_url.spec() : std::string();\
}\
' "$MENU_DELEGATE_CC"

# When an action is disabled on internal pages such as chrome://extensions,
# Chromium falls back to the extension context menu, whose obvious path is the
# details page. Prefer the extension options page when it exists.
grep -q 'chrome/browser/extensions/extension_tab_util.h' "$ACTION_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/extensions\/extension_view_host_factory.h"/a\#include "chrome/browser/extensions/extension_tab_util.h"' "$ACTION_DELEGATE_CC"
grep -q 'chrome/browser/profiles/profile.h' "$ACTION_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/extensions\/extension_tab_util.h"/a\#include "chrome/browser/profiles/profile.h"' "$ACTION_DELEGATE_CC"
grep -q 'chrome/browser/ui/browser_window/public/browser_window_interface.h' "$ACTION_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/profiles\/profile.h"/a\#include "chrome/browser/ui/browser_window/public/browser_window_interface.h"' "$ACTION_DELEGATE_CC"
grep -q 'extensions/browser/extension_registry.h' "$ACTION_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/ui\/browser_window\/public\/browser_window_interface.h"/a\#include "extensions/browser/extension_registry.h"' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|void ExtensionActionDelegateAndroid::ShowContextMenuAsFallback\(\) \{\n  toolbar_android_->ShowContextMenu\(action_id_\);\n\}|void ExtensionActionDelegateAndroid::ShowContextMenuAsFallback() {\n  const extensions::Extension* extension =\n      extensions::ExtensionRegistry::Get(browser_->GetProfile())\n          ->enabled_extensions()\n          .GetByID(action_id_);\n  if (extension &&\n      extensions::ExtensionTabUtil::OpenOptionsPage(extension, browser_)) {\n    return;\n  }\n\n  toolbar_android_->ShowContextMenu(action_id_);\n}|' "$ACTION_DELEGATE_CC"

# Use a stable but unique unpack directory for ZIP-installed extensions.
# The original random zipname_XXXXXX directory breaks after updates; a plain
# zip basename collides when two ZIPs share a display name. Hash the ZIP content
# so identical ZIPs update in place while different ZIPs never overwrite each
# other.
grep -q 'base/hash/sha1.h' "$ZIP_INSTALLER" || \
    sed -i '/#include "base\/functional\/callback_helpers.h"/a\#include "base/hash/sha1.h"' "$ZIP_INSTALLER"
grep -q 'base/strings/string_number_conversions.h' "$ZIP_INSTALLER" || \
    sed -i '/#include "base\/hash\/sha1.h"/a\#include "base/strings/string_number_conversions.h"' "$ZIP_INSTALLER"
ZIP_HASH_DIR_BLOCK='  std::string zip_contents;
  if (!base::ReadFileToString(zip_file, &zip_contents)) {
    return ZipResultVariant{std::string(kExtensionHandlerFileUnzipError)};
  }

  std::string zip_hash =
      base::HexEncodeLower(base::SHA1HashString(zip_contents)).substr(0, 12);
  base::FilePath unzip_dir = root_unzip_dir.Append(
      zip_file.RemoveExtension().BaseName().value() + FILE_PATH_LITERAL("_") +
      base::FilePath::FromASCII(zip_hash).value());
  if (base::PathExists(unzip_dir) &&
      !base::DeletePathRecursively(unzip_dir)) {
    return ZipResultVariant{ErrorUtils::FormatErrorMessage(
        kExtensionHandlerZippedDirError,
        base::UTF16ToUTF8(unzip_dir.LossyDisplayName()))};
  }
  if (!base::CreateDirectory(unzip_dir)) {
    return ZipResultVariant{ErrorUtils::FormatErrorMessage(
        kExtensionHandlerZippedDirError,
        base::UTF16ToUTF8(unzip_dir.LossyDisplayName()))};
  }'
export ZIP_HASH_DIR_BLOCK
perl -0pi -e 'BEGIN { $r = $ENV{"ZIP_HASH_DIR_BLOCK"}; } s|  // Create the root of the unique directory for the \.zip file\.\n  base::FilePath::StringType dir_name =\n      zip_file\.RemoveExtension\(\)\.BaseName\(\)\.value\(\) \+ FILE_PATH_LITERAL\("_"\);\n\n  // Creates the full unique directory path as unzip_dir\.\n  base::FilePath unzip_dir;\n  if \(!base::CreateTemporaryDirInDir\(root_unzip_dir, dir_name, &unzip_dir\)\) \{\n    return ZipResultVariant\{ErrorUtils::FormatErrorMessage\(\n        kExtensionHandlerZippedDirError,\n        base::UTF16ToUTF8\(unzip_dir\.LossyDisplayName\(\)\)\)\};\n  \}|$r|; s|  base::FilePath unzip_dir = root_unzip_dir.Append\(\n      zip_file\.RemoveExtension\(\)\.BaseName\(\)\);\n  if \(!base::CreateDirectory\(unzip_dir\)\) \{\n    return ZipResultVariant\{ErrorUtils::FormatErrorMessage\(\n        kExtensionHandlerZippedDirError,\n        base::UTF16ToUTF8\(unzip_dir\.LossyDisplayName\(\)\)\)\};\n  \}|$r|' "$ZIP_INSTALLER"
unset ZIP_HASH_DIR_BLOCK

# Folder-based local extensions also need a stable profile-owned copy on
# Android. The original SAF/UnpackedExtensions path can become unreadable after
# another local extension install, an app update, or garbage collection.
perl -0pi -e 's|  file_path = \*vp;\n#endif  // BUILDFLAG\(IS_ANDROID\)|  file_path = *vp;\n\n  base::FilePath local_unpacked_dir =\n      Profile::FromBrowserContext(browser_context())\n          ->GetPath()\n          .Append(FILE_PATH_LITERAL("Local Extension Install Files"))\n          .Append(FILE_PATH_LITERAL("Unpacked Folders"));\n  base::FilePath stable_file_path =\n      local_unpacked_dir.Append(file_path.BaseName());\n  if (base::CreateDirectory(local_unpacked_dir)) {\n    if (base::PathExists(stable_file_path)) {\n      base::DeletePathRecursively(stable_file_path);\n    }\n    if (base::CopyDirectory(file_path, stable_file_path, true)) {\n      file_path = stable_file_path;\n    }\n  }\n#endif  // BUILDFLAG(IS_ANDROID)|' "$DEV_PRIVATE_FUNCTIONS"

# ZIP-installed local extensions must not live under
# registrar->unpacked_install_directory(); ExtensionGarbageCollector scans that
# directory and can delete ZIP unpack dirs that are not yet or no longer exactly
# reflected in prefs. Keep Android local ZIP payloads in our persistent local
# extension store instead.
perl -0pi -e 's|  if \(MatchesExtension\(file, FILE_PATH_LITERAL\("\.zip"\)\)\) \{\n    ExtensionRegistrar\* registrar = ExtensionRegistrar::Get\(browser_context\(\)\);\n    ZipFileInstaller::Create\(\n        GetExtensionFileTaskRunner\(\),\n        MakeRegisterInExtensionServiceCallback\(browser_context\(\)\)\)\n        ->InstallZipFileToUnpackedExtensionsDir\(\n            file\.path, registrar->unpacked_install_directory\(\)\);\n  \} else \{|  if (MatchesExtension(file, FILE_PATH_LITERAL(".zip"))) {\n    base::FilePath local_zip_unpacked_dir =\n        Profile::FromBrowserContext(browser_context())\n            ->GetPath()\n            .Append(FILE_PATH_LITERAL("Local Extension Install Files"))\n            .Append(FILE_PATH_LITERAL("Unpacked Extensions"));\n    ZipFileInstaller::Create(\n        GetExtensionFileTaskRunner(),\n        MakeRegisterInExtensionServiceCallback(browser_context()))\n        ->InstallZipFileToUnpackedExtensionsDir(file.path,\n                                                local_zip_unpacked_dir);\n  } else {|' "$DEV_PRIVATE_FUNCTIONS"

# OpenOptionsPage uses Profile as a BrowserContext. Include the full Profile
# type so the conversion is visible to the C++ compiler.
grep -q 'chrome/browser/profiles/profile.h' "$MENU_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/extensions\/extension_tab_util.h"/a\#include "chrome/browser/profiles/profile.h"' "$MENU_DELEGATE_CC"

# Keep local zip/crx/unpacked extensions out of WebStore content verification.
sed -i 's|if (!InstallVerifier::IsFromStore(extension, context_)) {|if (!extension.from_webstore()) {|' "$VERIFIER"

# Do not let extension main-frame blocks/redirects leave the browser restored
# into a blank or invalid chrome-extension page. Subresources remain filterable.
if ! grep -q 'WebRequestResourceType::MAIN_FRAME) { break; }' "$WEB_REQUEST_ROUTER"; then
    sed -i '/case DNRRequestAction::Type::BLOCK:/,/case DNRRequestAction::Type::ALLOW:/ s|ClearPendingCallbacks(browser_context, \*request);|if (request->web_request_type == WebRequestResourceType::MAIN_FRAME) { break; }\n          ClearPendingCallbacks(browser_context, *request);|' "$WEB_REQUEST_ROUTER"
    sed -i '/case DNRRequestAction::Type::REDIRECT:/,/case DNRRequestAction::Type::MODIFY_HEADERS:/ s|ClearPendingCallbacks(browser_context, \*request);|if (request->web_request_type == WebRequestResourceType::MAIN_FRAME) { break; }\n          ClearPendingCallbacks(browser_context, *request);|' "$WEB_REQUEST_ROUTER"
fi
perl -0pi -e 's|  if \(request->web_request_type == WebRequestResourceType::MAIN_FRAME\) \{\n    canceled_by_extension\.reset\(\);\n    if \(blocked_request\.new_url && !blocked_request\.new_url->is_empty\(\) &&\n        !blocked_request\.new_url->SchemeIs\("chrome-extension"\)\) \{\n      \*blocked_request\.new_url = GURL\(\);\n    \}\n  \}|  // Helium: ignore extension main-frame cancel/redirect results. Ad blockers\n  // can otherwise leave a restored startup tab with an empty WebContents.\n  if (request->web_request_type == WebRequestResourceType::MAIN_FRAME) {\n    canceled_by_extension.reset();\n    if (blocked_request.new_url && !blocked_request.new_url->is_empty()) {\n      *blocked_request.new_url = GURL();\n    }\n  }|' "$WEB_REQUEST_ROUTER"
grep -q 'canceled_by_extension.reset();' "$WEB_REQUEST_ROUTER" || \
    sed -i '/  const bool redirected =/i\
  // Helium: ignore extension main-frame cancel/redirect results. Ad blockers\
  // can otherwise leave a restored startup tab with an empty WebContents.\
  if (request->web_request_type == WebRequestResourceType::MAIN_FRAME) {\
    canceled_by_extension.reset();\
    if (blocked_request.new_url \&\& !blocked_request.new_url->is_empty()) {\
      *blocked_request.new_url = GURL();\
    }\
  }\
' "$WEB_REQUEST_ROUTER"

# Do not fake developer mode in the UI. Fresh installs should start with
# developer mode disabled, and the load-unpacked backend checks the real pref.
perl -0pi -e 's|  info\.in_developer_mode = true;|  info.in_developer_mode = !info.is_child_account \&\&\n                           prefs->GetBoolean(prefs::kExtensionsUIDeveloperMode);|' "$PROFILE_INFO"

# Startup stability: do not purge renderer caches automatically on every start.
sed -i '/clearVolatileRendererCaches();/d' "$CTA"

# Startup recovery: a previously restored chrome-extension:// tab can point to
# a local extension path that no longer exists. Restore those top-level entries
# to NTP so extension override logic can recreate the page instead of reopening
# a broken saved tab on every launch.
if grep -q 'private static boolean shouldReplaceUrlForRestore' "$TAB_STORE"; then
    perl -0pi -e 's#private static boolean shouldReplaceUrlForRestore\(\@Nullable String url\) \{\n.*?\n    \}#private static boolean shouldReplaceUrlForRestore(\@Nullable String url) {\n        return TextUtils.isEmpty(url)\n                || url.startsWith("chrome-extension://")\n                || url.equals("about:blank")\n                || url.startsWith("chrome://newtab")\n                || url.startsWith("chrome://new-tab-page")\n                || url.startsWith("chrome-native://newtab");\n    }#s; s#UrlConstants\.VERSION_URL#UrlConstants.NTP_URL#g' "$TAB_STORE"
else
    grep -q 'org.chromium.components.embedder_support.util.UrlConstants' "$TAB_STORE" || \
        sed -i '/import org.chromium.components.embedder_support.util.UrlUtilities;/i\import org.chromium.components.embedder_support.util.UrlConstants;' "$TAB_STORE"
    sed -i '/private static boolean sDeferredStartupComplete;/a\
\
    private static boolean shouldReplaceUrlForRestore(@Nullable String url) {\
        return TextUtils.isEmpty(url)\
                || url.startsWith("chrome-extension://")\
                || url.equals("about:blank")\
                || url.startsWith("chrome://newtab")\
                || url.startsWith("chrome://new-tab-page")\
                || url.startsWith("chrome-native://newtab");\
    }\
\
    private static String safeUrlForRestore(@Nullable String url) {\
        return shouldReplaceUrlForRestore(url) ? UrlConstants.NTP_URL : assumeNonNull(url);\
    }' "$TAB_STORE"
    sed -i '/boolean isIncognito = isIncognitoTabBeingRestored(tabToRestore, tabState);/a\
        if (shouldReplaceUrlForRestore(tabToRestore.url)) {\
            tabState = null;\
            tabToRestore =\
                    new TabRestoreDetails(\
                            tabToRestore.id,\
                            tabToRestore.originalIndex,\
                            tabToRestore.isIncognito,\
                            safeUrlForRestore(tabToRestore.url),\
                            tabToRestore.fromMerge);\
        }' "$TAB_STORE"
fi

# Startup stability: extension toolbar button visibility must tolerate missing
# toolbar variants during first-launch layout inflation.
perl -0pi -e 'if (!/setHeliumMenuButtonVisibility/) { s|    private void showIphInternal\(\) \{|    private void setHeliumMenuButtonVisibility(boolean visible) {\n        if (mContainer == null) return;\n        View menuButton = mContainer.findViewById(R.id.extensions_menu_button);\n        if (menuButton == null) return;\n        menuButton.setVisibility(visible ? View.VISIBLE : View.GONE);\n    }\n\n    private void showIphInternal() {| }' "$TOOLBAR"

sed -i 's|if (mPrefService.getBoolean(Pref.PIN_EXTENSIONS_MENU_BUTTON)) { mContainer.findViewById(R.id.extensions_menu_button).setVisibility(View.VISIBLE); } else { mContainer.findViewById(R.id.extensions_menu_button).setVisibility(View.GONE); }|        setHeliumMenuButtonVisibility(mPrefService.getBoolean(Pref.PIN_EXTENSIONS_MENU_BUTTON));|' "$TOOLBAR"
sed -i 's|mContainer.findViewById(R.id.extensions_menu_button).setVisibility(isMenuButtonPinned() ? View.VISIBLE : View.GONE);|                setHeliumMenuButtonVisibility(isMenuButtonPinned());|' "$TOOLBAR"

perl -0pi -e 's|        mContainer\.findViewById\(R\.id\.extensions_menu_button\)\.setVisibility\(visibility\);|        View menuButton = mContainer.findViewById(R.id.extensions_menu_button);\n        if (menuButton != null) {\n            menuButton.setVisibility(visibility);\n        }|' "$TOOLBAR"

echo "Applied hotfixes to $SRC_DIR"
