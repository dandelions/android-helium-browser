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
ACTION_DELEGATE_H=chrome/browser/ui/android/extensions/extension_action_delegate_android.h
ACTION_LIST_MEDIATOR=chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionActionListMediator.java
MENU_COORDINATOR=chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuCoordinator.java
MENU_VIEW_MODEL=chrome/browser/ui/extensions/extensions_menu_view_model.cc
TABS_API_CC=chrome/browser/extensions/api/tabs/tabs_api.cc
EXTENSION_TAB_UTIL_CC=chrome/browser/extensions/extension_tab_util.cc
EXTENSION_TAB_UTIL_H=chrome/browser/extensions/extension_tab_util.h
ZIP_INSTALLER=extensions/browser/zipfile_installer.cc
WEB_REQUEST_ROUTER=extensions/browser/api/web_request/extension_web_request_event_router.cc
EXTENSION_PREFS=extensions/browser/extension_prefs.cc
TAB_STORE=chrome/android/java/src/org/chromium/chrome/browser/tabmodel/TabPersistentStoreImpl.java
ANDROID_MANIFEST=chrome/android/java/AndroidManifest.xml
CUSTOM_TAB_MINIMIZATION_MANAGER=chrome/android/java/src/org/chromium/chrome/browser/customtabs/features/minimizedcustomtab/CustomTabMinimizationManager.java
MINIMIZED_FEATURE_UTILS=chrome/android/java/src/org/chromium/chrome/browser/customtabs/features/minimizedcustomtab/MinimizedFeatureUtils.java
DEVTOOLS_INTENT_DATA_PROVIDER=chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsIntentDataProvider.java
BASE_CUSTOM_TAB_ROOT_UI_COORDINATOR=chrome/android/java/src/org/chromium/chrome/browser/customtabs/BaseCustomTabRootUiCoordinator.java
DEVTOOLS_ACTIVITY=chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java
DEVTOOLS_WINDOW_ANDROID_JAVA=chrome/browser/devtools/android/java/src/org/chromium/chrome/browser/devtools/DevToolsWindowAndroid.java
DEVTOOLS_WINDOW_ANDROID_CC=chrome/browser/devtools/android/devtools_window_android.cc
DEVTOOLS_WINDOW_CC=chrome/browser/devtools/devtools_window.cc
JS_DIALOG_MANAGER=components/javascript_dialogs/app_modal_dialog_manager.cc
UNDO_BAR=chrome/android/java/src/org/chromium/chrome/browser/undo_tab_close_snackbar/UndoBarController.java
UNGOOGLED_FLAGS=chrome/browser/ungoogled_flag_entries.h
ABOUT_FLAGS=chrome/browser/about_flags.cc
NAV_POLICY=content/renderer/render_frame_impl.cc
WINDOW_OPEN_TRAITS=ui/base/mojom/window_open_disposition_mojom_traits.h
WEB_CONTENTS_IMPL=content/browser/web_contents/web_contents_impl.cc

for file in "$BRIDGE" "$MENU_MEDIATOR" "$TOOLBAR" "$CTA" "$VERIFIER" "$PROFILE_INFO" "$DEV_PRIVATE_FUNCTIONS" "$TIMESTAMP_GNI" "$CONTENT_SETTINGS_FEATURES" "$APP_MENU_DELEGATE" "$MENU_DELEGATE_CC" "$MENU_DELEGATE_H" "$ACTION_DELEGATE_CC" "$ACTION_DELEGATE_H" "$ACTION_LIST_MEDIATOR" "$MENU_COORDINATOR" "$MENU_VIEW_MODEL" "$ZIP_INSTALLER" "$WEB_REQUEST_ROUTER" "$EXTENSION_PREFS" "$TAB_STORE" "$ANDROID_MANIFEST" "$CUSTOM_TAB_MINIMIZATION_MANAGER" "$MINIMIZED_FEATURE_UTILS" "$DEVTOOLS_INTENT_DATA_PROVIDER" "$BASE_CUSTOM_TAB_ROOT_UI_COORDINATOR" "$DEVTOOLS_ACTIVITY" "$DEVTOOLS_WINDOW_ANDROID_JAVA" "$DEVTOOLS_WINDOW_ANDROID_CC" "$DEVTOOLS_WINDOW_CC" "$JS_DIALOG_MANAGER" "$UNDO_BAR" "$ABOUT_FLAGS" "$NAV_POLICY" "$WINDOW_OPEN_TRAITS" "$WEB_CONTENTS_IMPL"; do
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

# Make Android DevTools behave as a normal desktop-mode window.
perl -0pi -e 's|(<activity\n            android:name="org\.chromium\.chrome\.browser\.devtools\.DevToolsActivity"\n            android:theme="\@style/Theme\.Chromium\.Activity"\n            android:exported="false"\n)(?!            android:resizeableActivity="true"\n)|$1            android:resizeableActivity="true"\n|' "$ANDROID_MANIFEST"
perl -0pi -e 's|(<activity\n            android:name="org\.chromium\.chrome\.browser\.devtools\.DevToolsActivity"(?:(?!</activity>).)*?            android:resizeableActivity="true"\n)(?!            android:supportsPictureInPicture="true"\n)|$1            android:supportsPictureInPicture="true"\n|s' "$ANDROID_MANIFEST"
perl -0pi -e 's|(<activity\n            android:name="org\.chromium\.chrome\.browser\.devtools\.DevToolsActivity"(?:(?!</activity>).)*?            \{\{ self\.extra_web_rendering_activity_definitions\(\) \}\}\n)(?!            <property android:name="android\.window\.PROPERTY_SUPPORTS_MULTI_INSTANCE_SYSTEM_UI")|$1            <property android:name="android.window.PROPERTY_SUPPORTS_MULTI_INSTANCE_SYSTEM_UI"\n                android:value="true" />\n|s' "$ANDROID_MANIFEST"
grep -q 'org.chromium.chrome.browser.flags.ActivityType' "$CUSTOM_TAB_MINIMIZATION_MANAGER" || \
    sed -i '/import org.chromium.chrome.browser.customtabs.CustomTabsConnection;/a\import org.chromium.chrome.browser.flags.ActivityType;' "$CUSTOM_TAB_MINIMIZATION_MANAGER"
grep -q 'mIntentData.getActivityType() == ActivityType.DEV_TOOLS' "$CUSTOM_TAB_MINIMIZATION_MANAGER" || \
    sed -i '/if (!(mTabProvider.get() != null)) return;/a\
        if (mIntentData.getActivityType() == ActivityType.DEV_TOOLS) {\
            mActivity.moveTaskToBack(true);\
            return;\
        }' "$CUSTOM_TAB_MINIMIZATION_MANAGER"
grep -q 'org.chromium.chrome.browser.flags.ActivityType' "$MINIMIZED_FEATURE_UTILS" || \
    sed -i '/import org.chromium.chrome.browser.flags.ChromeFeatureList;/a\import org.chromium.chrome.browser.flags.ActivityType;' "$MINIMIZED_FEATURE_UTILS"
grep -q 'intentDataProvider.getActivityType() == ActivityType.DEV_TOOLS' "$MINIMIZED_FEATURE_UTILS" || \
    sed -i '/public static boolean shouldEnableMinimizedCustomTabs(/,/if (intentDataProvider.hasTargetNetwork()) return false;/ s|if (intentDataProvider.hasTargetNetwork()) return false;|if (intentDataProvider.getActivityType() == ActivityType.DEV_TOOLS) return false;\n        if (intentDataProvider.hasTargetNetwork()) return false;|' "$MINIMIZED_FEATURE_UTILS"
sed -i '/public @TitleVisibility int getTitleVisibilityState()/,/^    }/ s|return TitleVisibility.VISIBLE;|return TitleVisibility.HIDDEN;|' "$DEVTOOLS_INTENT_DATA_PROVIDER"
sed -i '/public boolean isCloseButtonEnabled()/,/^    }/ s|return false;|return true;|' "$DEVTOOLS_INTENT_DATA_PROVIDER"
sed -i 's#connection.shouldEnableOmniboxForIntent(mIntentDataProvider.get());#connection.shouldEnableOmniboxForIntent(mIntentDataProvider.get())\n                        || mIntentDataProvider.get().getActivityType() == ActivityType.DEV_TOOLS;#' "$BASE_CUSTOM_TAB_ROOT_UI_COORDINATOR"
grep -q 'org.chromium.cc.input.BrowserControlsState' "$DEVTOOLS_ACTIVITY" || \
    sed -i '/import org.chromium.base.ContextUtils;/a\import org.chromium.cc.input.BrowserControlsState;' "$DEVTOOLS_ACTIVITY"
grep -q 'android.view.Gravity' "$DEVTOOLS_ACTIVITY" || \
    sed -i '/import android.content.Intent;/a\import android.view.Gravity;' "$DEVTOOLS_ACTIVITY"
grep -q 'android.view.ViewGroup' "$DEVTOOLS_ACTIVITY" || \
    sed -i '/import android.view.Gravity;/a\import android.view.ViewGroup;' "$DEVTOOLS_ACTIVITY"
grep -q 'android.widget.Button' "$DEVTOOLS_ACTIVITY" || \
    sed -i '/import android.view.ViewGroup;/a\import android.widget.Button;' "$DEVTOOLS_ACTIVITY"
grep -q 'android.widget.FrameLayout' "$DEVTOOLS_ACTIVITY" || \
    sed -i '/import android.widget.Button;/a\import android.widget.FrameLayout;' "$DEVTOOLS_ACTIVITY"
grep -q 'addInspectedPageSwitcher(WebContents devToolsWebContents)' "$DEVTOOLS_ACTIVITY" || \
    perl -0pi -e 's~(\n    \@Override\n    public void finishNativeInitialization\(\) \{)~\n    private void addInspectedPageSwitcher(WebContents devToolsWebContents) {\n        Button switchButton = new Button(this);\n        switchButton.setText("Page");\n        switchButton.setAllCaps(false);\n        switchButton.setOnClickListener(\n                v -> DevToolsWindowAndroid.activateInspectedPage(devToolsWebContents));\n        FrameLayout.LayoutParams params =\n                new FrameLayout.LayoutParams(\n                        ViewGroup.LayoutParams.WRAP_CONTENT,\n                        ViewGroup.LayoutParams.WRAP_CONTENT,\n                        Gravity.TOP | Gravity.END);\n        int margin = (int) (8 * getResources().getDisplayMetrics().density);\n        params.setMargins(margin, margin, margin, margin);\n        addContentView(switchButton, params);\n    }\n$1~' "$DEVTOOLS_ACTIVITY"
grep -q 'addInspectedPageSwitcher(webContents)' "$DEVTOOLS_ACTIVITY" || \
    perl -0pi -e 's~(DevToolsWindowAndroid\.attachToBrowser\(\n                    webContents, task\.getOrCreateNativeBrowserWindowPtr\(profile\)\);\n)~$1            addInspectedPageSwitcher(webContents);\n~' "$DEVTOOLS_ACTIVITY"
grep -q 'setBrowserControlsState(BrowserControlsState.SHOWN)' "$DEVTOOLS_ACTIVITY" || \
    sed -i '/super.finishNativeInitialization();/a\        getCustomTabToolbarCoordinator().setBrowserControlsState(BrowserControlsState.SHOWN);' "$DEVTOOLS_ACTIVITY"
grep -q 'public static void activateInspectedPage' "$DEVTOOLS_WINDOW_ANDROID_JAVA" || \
    perl -0pi -e 's~(\n    /\*\*\n     \* Attaches the DevTools frontend web contents to the browser window\.)~\n    public static void activateInspectedPage(WebContents webContents) {\n        DevToolsWindowAndroidJni.get().activateInspectedPage(webContents);\n    }\n$1~' "$DEVTOOLS_WINDOW_ANDROID_JAVA"
grep -q '^        void activateInspectedPage(WebContents webContents);' "$DEVTOOLS_WINDOW_ANDROID_JAVA" || \
    sed -i '/void attachToBrowser(WebContents webContents, long nativeBrowserWindowPtr);/i\        void activateInspectedPage(WebContents webContents);\n' "$DEVTOOLS_WINDOW_ANDROID_JAVA"
grep -q 'web_contents_delegate.h' "$DEVTOOLS_WINDOW_ANDROID_CC" || \
    sed -i '/#include "content\/public\/browser\/web_contents.h"/a\#include "content/public/browser/web_contents_delegate.h"' "$DEVTOOLS_WINDOW_ANDROID_CC"
grep -q 'JNI_DevToolsWindowAndroid_ActivateInspectedPage' "$DEVTOOLS_WINDOW_ANDROID_CC" || \
    perl -0pi -e 's~(\nstatic void JNI_DevToolsWindowAndroid_AttachToBrowser\()~\nstatic void JNI_DevToolsWindowAndroid_ActivateInspectedPage(\n    JNIEnv* env,\n    const jni_zero::JavaRef<jobject>& java_web_contents) {\n#if BUILDFLAG(ENABLE_DEVTOOLS_FRONTEND)\n  content::WebContents* web_contents =\n      content::WebContents::FromJavaWebContents(java_web_contents);\n  DevToolsWindow* window = DevToolsWindow::AsDevToolsWindow(web_contents);\n  if (!window) {\n    return;\n  }\n  content::WebContents* inspected_web_contents =\n      window->GetInspectedWebContents();\n  if (!inspected_web_contents || !inspected_web_contents->GetDelegate()) {\n    return;\n  }\n  inspected_web_contents->GetDelegate()->ActivateContents(\n      inspected_web_contents);\n  inspected_web_contents->Focus();\n#endif\n}\n$1~' "$DEVTOOLS_WINDOW_ANDROID_CC"
grep -q 'components/tabs/public/tab_interface.h' "$DEVTOOLS_WINDOW_CC" || \
    sed -i '/#include "components\/strings\/grit\/components_strings.h"/a\#include "components/tabs/public/tab_interface.h"' "$DEVTOOLS_WINDOW_CC"
grep -q 'HeliumAndroidDevToolsSameWindow' "$DEVTOOLS_WINDOW_CC" || \
    perl -0pi -e 's~#if BUILDFLAG\(IS_ANDROID\)\n  if \(!owned_main_web_contents_ \|\| launched_activity_\) \{\n    return;\n  \}\n  JNIEnv\* env = base::android::AttachCurrentThread\(\);\n  Java_DevToolsActivity_launchDevToolsActivity\(\n      env, main_web_contents_->GetJavaWebContents\(\)\);\n\n  launched_activity_ = true;\n\n  OverrideAndSyncDevToolsRendererPrefs\(\);~#if BUILDFLAG(IS_ANDROID)\n  if (!owned_main_web_contents_ || launched_activity_) {\n    return;\n  }\n  content::WebContents* inspected_web_contents = GetInspectedWebContents();\n  tabs::TabInterface* inspected_tab =\n      inspected_web_contents\n          ? tabs::TabInterface::MaybeGetFromContents(inspected_web_contents)\n          : nullptr;\n  BrowserWindowInterface* inspected_browser =\n      inspected_tab ? inspected_tab->GetBrowserWindowInterface() : nullptr;\n  TabListInterface* inspected_tab_list =\n      inspected_browser ? TabListInterface::From(inspected_browser) : nullptr;\n  if (inspected_tab_list) {\n    // HeliumAndroidDevToolsSameWindow: put DevTools in the inspected page window.\n    AttachToBrowser(inspected_browser);\n  } else {\n    JNIEnv* env = base::android::AttachCurrentThread();\n    Java_DevToolsActivity_launchDevToolsActivity(\n        env, main_web_contents_->GetJavaWebContents());\n  }\n\n  launched_activity_ = true;\n\n  OverrideAndSyncDevToolsRendererPrefs();~' "$DEVTOOLS_WINDOW_CC"
perl -0pi -e 's~(#if BUILDFLAG\(IS_ANDROID\)\n)    NOTIMPLEMENTED\(\);\n(#else\n    if \(browser_\) \{)~$1    WebContents* inspected_tab = GetInspectedWebContents();\n    if (inspected_tab && inspected_tab->GetDelegate()) {\n      inspected_tab->GetDelegate()->ActivateContents(inspected_tab);\n      inspected_tab->Focus();\n    }\n$2~' "$DEVTOOLS_WINDOW_CC"
perl -0pi -e 's~(#if BUILDFLAG\(IS_ANDROID\)\n)  NOTIMPLEMENTED\(\);\n(#else\n  if \(is_docked_ && GetInspectedBrowserWindow\(\)\) \{)~$1  tabs::TabInterface* devtools_tab =\n      tabs::TabInterface::MaybeGetFromContents(main_web_contents_);\n  BrowserWindowInterface* devtools_browser =\n      devtools_tab ? devtools_tab->GetBrowserWindowInterface() : nullptr;\n  TabListInterface* tab_list =\n      devtools_browser ? TabListInterface::From(devtools_browser) : nullptr;\n  if (tab_list && devtools_tab) {\n    tab_list->ActivateTab(devtools_tab->GetHandle());\n    main_web_contents_->Focus();\n  }\n$2~' "$DEVTOOLS_WINDOW_CC"
grep -q 'InspectElementCompleted.AndroidActivateWindow' "$DEVTOOLS_WINDOW_CC" || \
    perl -0pi -e 's~void DevToolsWindow::InspectElementCompleted\(\) \{\n  if \(!inspect_element_start_time_\.is_null\(\)\) \{\n    UMA_HISTOGRAM_TIMES\("DevTools\.InspectElement",\n                        base::TimeTicks::Now\(\) - inspect_element_start_time_\);\n    inspect_element_start_time_ = base::TimeTicks\(\);\n  \}\n\}~void DevToolsWindow::InspectElementCompleted() {\n  if (!inspect_element_start_time_.is_null()) {\n    UMA_HISTOGRAM_TIMES("DevTools.InspectElement",\n                        base::TimeTicks::Now() - inspect_element_start_time_);\n    inspect_element_start_time_ = base::TimeTicks();\n  }\n#if BUILDFLAG(IS_ANDROID)\n  // InspectElementCompleted.AndroidActivateWindow: return to DevTools after picking an element.\n  ActivateWindow();\n#endif\n}~' "$DEVTOOLS_WINDOW_CC"
grep -q 'tab_list->ActivateTab(tab->GetHandle())' "$DEVTOOLS_WINDOW_CC" || \
    perl -0pi -e 's~  auto\* tab_list = TabListInterface::From\(browser\);\n  if \(!tab_list\) \{\n    return;\n  \}\n  tab_list->InsertWebContentsAt\(0, std::move\(owned_web_contents\), false,\n                                std::nullopt\);~  auto* tab_list = TabListInterface::From(browser);\n  if (!tab_list) {\n    return;\n  }\n  browser_ = browser;\n  tabs::TabInterface* tab = tab_list->InsertWebContentsAt(\n      0, std::move(owned_web_contents), false, std::nullopt);\n  if (tab) {\n    tab_list->ActivateTab(tab->GetHandle());\n  }~' "$DEVTOOLS_WINDOW_CC"

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
elif [ ! -f "$UNGOOGLED_FLAGS" ] && ! grep -q '"open-new-links-in-current-tab"' "$ABOUT_FLAGS"; then
    sed -i '/#include "chrome\/browser\/unexpire_flags_gen.inc"/a\
    {"open-new-links-in-current-tab",\
     "Open new links in current tab",\
     "Forces site-requested new tabs and windows to navigate in the current tab.",\
     kOsAndroid, SINGLE_VALUE_TYPE("open-new-links-in-current-tab")},' "$ABOUT_FLAGS"
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
grep -q '#include "base/command_line.h"' "$WEB_CONTENTS_IMPL" || \
    sed -i '0,/^#include /s|^#include |#include "base/command_line.h"\n#include |' "$WEB_CONTENTS_IMPL"
if ! grep -q 'Helium: force new-tab OpenURL dispositions into current tab' "$WEB_CONTENTS_IMPL"; then
    sed -i '/WebContents\* WebContentsImpl::OpenURL(/,/^#if DCHECK_IS_ON()/ { /^#if DCHECK_IS_ON()/i\
  // Helium: force new-tab OpenURL dispositions into current tab.\
  if (base::CommandLine::ForCurrentProcess()->HasSwitch(\
          "open-new-links-in-current-tab") \&\&\
      (params.disposition == WindowOpenDisposition::NEW_FOREGROUND_TAB ||\
       params.disposition == WindowOpenDisposition::NEW_BACKGROUND_TAB ||\
       params.disposition == WindowOpenDisposition::NEW_POPUP ||\
       params.disposition == WindowOpenDisposition::NEW_WINDOW)) {\
    OpenURLParams current_tab_params(params);\
    current_tab_params.disposition = WindowOpenDisposition::CURRENT_TAB;\
    return OpenURL(current_tab_params, std::move(navigation_handle_callback));\
  }\

}' "$WEB_CONTENTS_IMPL"
fi

# Repair a bad intermediate JNI annotation generated by an older patch.
sed -i 's|                ("std::string") String extensionId);|                @JniType("std::string") String extensionId);|' "$BRIDGE"

# Do not show the "Closed tab - Undo" snackbar. Commit pending tab closures
# immediately so no undo UI is queued.
grep -q 'Helium: disable tab close undo snackbar' "$UNDO_BAR" || \
    sed -i '/if (closedTabs.isEmpty() && savedTabGroupSyncIds.isEmpty()) return;/a\
        if (shouldDisableUndoSnackbar()) {\
            for (Tab closedTab : closedTabs) {\
                commitTabClosure(closedTab.getId());\
            }\
            return;\
        }' "$UNDO_BAR"
grep -q 'private static boolean shouldDisableUndoSnackbar' "$UNDO_BAR" || \
    sed -i '/private void showUndoBar(/i\
    private static boolean shouldDisableUndoSnackbar() {\
        // Helium: disable tab close undo snackbar.\
        return true;\
    }\
' "$UNDO_BAR"

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
sed -i 's|(view) -> mToolbarBridge.executeUserAction(entry.id, InvocationSource.TOOLBAR_BUTTON))|(view) -> mMenuBridge.executeAction(entry.id))|' "$MENU_MEDIATOR"
sed -i 's|(view) -> openExtensionOptionsFromMenu(entry.id))|(view) -> mMenuBridge.executeAction(entry.id))|' "$MENU_MEDIATOR"
perl -0pi -e 's|if \(hasPoppedOutAction\(\) && itemWidth <= availableWidth\) \{\n            mCanShowPoppedOutAction = true;\n            return itemWidth;\n        \} else \{\n            mCanShowPoppedOutAction = false;\n            return 0;\n        \}|if (hasPoppedOutAction()) {\n            mCanShowPoppedOutAction = true;\n            return itemWidth;\n        } else {\n            mCanShowPoppedOutAction = false;\n            return 0;\n        }|' "$ACTION_LIST_MEDIATOR"
perl -0pi -e 's|if \(findIndexForId\(actionId\) == -1\) \{\n            mPoppedOutActionId = actionId;\n        \}|if (findIndexForId(actionId) == -1) {\n            mPoppedOutActionId = actionId;\n            mCanShowPoppedOutAction = true;\n            reconcileActionItems();\n        }|' "$ACTION_LIST_MEDIATOR"
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
grep -q 'build/build_config.h' "$ACTION_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/extensions\/extension_tab_util.h"/a\#include "build/build_config.h"' "$ACTION_DELEGATE_CC"
grep -q 'chrome/browser/profiles/profile.h' "$ACTION_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/extensions\/extension_tab_util.h"/a\#include "chrome/browser/profiles/profile.h"' "$ACTION_DELEGATE_CC"
grep -q 'chrome/browser/tab_list/tab_list_interface.h' "$ACTION_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/extensions\/extension_tab_util.h"/a\#include "chrome/browser/tab_list/tab_list_interface.h"' "$ACTION_DELEGATE_CC"
grep -q 'components/tabs/public/tab_interface.h' "$ACTION_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/extensions\/extension_tab_util.h"/a\#include "components/tabs/public/tab_interface.h"' "$ACTION_DELEGATE_CC"
grep -q 'chrome/browser/ui/browser_window/public/browser_window_interface.h' "$ACTION_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/profiles\/profile.h"/a\#include "chrome/browser/ui/browser_window/public/browser_window_interface.h"' "$ACTION_DELEGATE_CC"
grep -q 'extensions/browser/extension_registry.h' "$ACTION_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/ui\/browser_window\/public\/browser_window_interface.h"/a\#include "extensions/browser/extension_registry.h"' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|void ExtensionActionDelegateAndroid::ShowContextMenuAsFallback\(\) \{\n  const extensions::Extension\* extension =\n      extensions::ExtensionRegistry::Get\(browser_->GetProfile\(\)\)\n          ->enabled_extensions\(\)\n          \.GetByID\(action_id_\);\n  if \(extension &&\n      extensions::ExtensionTabUtil::OpenOptionsPage\(extension, browser_\)\) \{\n    return;\n  \}\n\n  toolbar_android_->ShowContextMenu\(action_id_\);\n\}|void ExtensionActionDelegateAndroid::ShowContextMenuAsFallback() {\n  toolbar_android_->ShowContextMenu(action_id_);\n}|' "$ACTION_DELEGATE_CC"

# Menu action popups should be anchored to the clicked menu row, not by
# temporarily popping the extension action into the toolbar.
perl -0pi -e 's|if \(hasPoppedOutAction\(\)\) \{\n            mCanShowPoppedOutAction = true;\n            return itemWidth;\n        \} else \{\n            mCanShowPoppedOutAction = false;\n            return 0;\n        \}|if (hasPoppedOutAction() && itemWidth <= availableWidth) {\n            mCanShowPoppedOutAction = true;\n            return itemWidth;\n        } else {\n            mCanShowPoppedOutAction = false;\n            return 0;\n        }|' "$ACTION_LIST_MEDIATOR"
perl -0pi -e 's|if \(findIndexForId\(actionId\) == -1\) \{\n            mPoppedOutActionId = actionId;\n            mCanShowPoppedOutAction = true;\n            reconcileActionItems\(\);\n        \}|if (findIndexForId(actionId) == -1) {\n            mPoppedOutActionId = actionId;\n        }|' "$ACTION_LIST_MEDIATOR"
grep -q 'org.chromium.chrome.browser.tabmodel.TabModelSelector' "$MENU_COORDINATOR" || \
    sed -i '/import org.chromium.chrome.browser.tabmodel.TabCreator;/a\import org.chromium.chrome.browser.tabmodel.TabModelSelector;' "$MENU_COORDINATOR"
grep -q 'org.chromium.components.embedder_support.contextmenu.ContextMenuPopulatorFactory' "$MENU_COORDINATOR" || \
    sed -i '/import org.chromium.chrome.browser.user_education.UserEducationHelper;/a\import org.chromium.components.embedder_support.contextmenu.ContextMenuPopulatorFactory;' "$MENU_COORDINATOR"
grep -q 'org.chromium.content_public.browser.selection.SelectionDropdownMenuDelegate' "$MENU_COORDINATOR" || \
    sed -i '/import org.chromium.content_public.browser.WebContents;/a\import org.chromium.content_public.browser.selection.SelectionDropdownMenuDelegate;' "$MENU_COORDINATOR"
grep -q 'org.chromium.ui.base.WindowAndroid' "$MENU_COORDINATOR" || \
    sed -i '/import org.chromium.content_public.browser.selection.SelectionDropdownMenuDelegate;/a\import org.chromium.ui.base.WindowAndroid;' "$MENU_COORDINATOR"
grep -q 'private final WindowAndroid mWindowAndroid;' "$MENU_COORDINATOR" || \
    sed -i '/private final TabCreator mTabCreator;/a\    private final WindowAndroid mWindowAndroid;' "$MENU_COORDINATOR"
grep -q 'mContextMenuPopulatorFactory' "$MENU_COORDINATOR" || \
    sed -i '/private final TabCreator mTabCreator;/a\    private final @Nullable ContextMenuPopulatorFactory mContextMenuPopulatorFactory;\n    private final @Nullable SelectionDropdownMenuDelegate mSelectionDropdownMenuDelegate;\n    private final TabModelSelector mTabModelSelector;' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n            WindowAndroid windowAndroid,){2,}|\n            WindowAndroid windowAndroid,|g' "$MENU_COORDINATOR"
grep -q 'WindowAndroid windowAndroid,' "$MENU_COORDINATOR" || \
    perl -0pi -e 's|(\n            ExtensionsToolbarBridge extensionsToolbarBridge,)|$1\n            WindowAndroid windowAndroid,|' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,){2,}|\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,|g' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n            ExtensionsToolbarBridge extensionsToolbarBridge,\n)            WindowAndroid windowAndroid,\n(\s*\@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,)|$1$2|g' "$MENU_COORDINATOR"
grep -q 'ContextMenuPopulatorFactory contextMenuPopulatorFactory,' "$MENU_COORDINATOR" || \
    perl -0pi -e 's|(\n            ExtensionsToolbarBridge extensionsToolbarBridge,)|$1\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,|' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;){2,}|\n        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;|g' "$MENU_COORDINATOR"
grep -q 'mContextMenuPopulatorFactory = contextMenuPopulatorFactory;' "$MENU_COORDINATOR" || \
    perl -0pi -e 's|(\n        mTabCreator = tabCreator;\n        mTask = task;\n        mProfile = profile;\n)|        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;\n$1|' "$MENU_COORDINATOR"
grep -q 'mContextMenuPopulatorFactory = contextMenuPopulatorFactory;' "$MENU_COORDINATOR" || \
    sed -i '/mExtensionsToolbarBridge = extensionsToolbarBridge;/a\        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;' "$MENU_COORDINATOR"
grep -q 'mWindowAndroid = windowAndroid;' "$MENU_COORDINATOR" || \
    sed -i '/mExtensionsToolbarBridge = extensionsToolbarBridge;/a\        mWindowAndroid = windowAndroid;' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n                        mContextMenuPopulatorFactory,\n                        mSelectionDropdownMenuDelegate,\n                        mTabModelSelector,){2,}|\n                        mContextMenuPopulatorFactory,\n                        mSelectionDropdownMenuDelegate,\n                        mTabModelSelector,|g' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n                        mWindowAndroid,){2,}|\n                        mWindowAndroid,|g' "$MENU_COORDINATOR"
perl -0pi -e 's~(\n                        (?:mExtensionsToolbarBridge|extensionsToolbarBridge),)(?!\n                        mWindowAndroid,)~$1\n                        mWindowAndroid,~' "$MENU_COORDINATOR"
perl -0pi -e 's~(\n                        mWindowAndroid,)(?!\n                        mContextMenuPopulatorFactory,)~$1\n                        mContextMenuPopulatorFactory,\n                        mSelectionDropdownMenuDelegate,\n                        mTabModelSelector,~' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n                        contextMenuPopulatorFactory,\n                        selectionDropdownMenuDelegate,\n                        tabModelSelector,){2,}|\n                        contextMenuPopulatorFactory,\n                        selectionDropdownMenuDelegate,\n                        tabModelSelector,|g' "$TOOLBAR"
perl -0pi -e 's~(\n                        windowAndroid,\n)                        contextMenuPopulatorFactory,\n                        selectionDropdownMenuDelegate,\n                        tabModelSelector,\n(\s*(?:task|mTask),)~$1$2~g' "$TOOLBAR"
perl -0pi -e 's|(\n                        mExtensionsToolbarBridge,\n)                        windowAndroid,\n(\s*contextMenuPopulatorFactory,)|$1$2|g' "$TOOLBAR"
perl -0pi -e 's~(\n                        currentTabSupplier,\n                        tabCreator,\n                        mExtensionsToolbarBridge,)(?!\n                        contextMenuPopulatorFactory,)~$1\n                        contextMenuPopulatorFactory,\n                        selectionDropdownMenuDelegate,\n                        tabModelSelector,~' "$TOOLBAR"
perl -0pi -e 's|mExtensionsToolbarBridge,\n                        mMenuButtonPinningDelegate,\n                        contextMenuPopulatorFactory,\n                        selectionDropdownMenuDelegate,\n                        tabModelSelector,|mExtensionsToolbarBridge,\n                        contextMenuPopulatorFactory,\n                        selectionDropdownMenuDelegate,\n                        tabModelSelector,\n                        mMenuButtonPinningDelegate,|' "$TOOLBAR"
grep -q 'import android.app.Activity;' "$MENU_MEDIATOR" || \
    sed -i '/import android.content.Context;/i\import android.app.Activity;' "$MENU_MEDIATOR"
grep -q 'import android.view.View;' "$MENU_MEDIATOR" || \
    sed -i '/import android.graphics.Bitmap;/a\import android.view.View;' "$MENU_MEDIATOR"
grep -q 'org.chromium.build.annotations.Nullable' "$MENU_MEDIATOR" || \
    sed -i '/import org.chromium.build.annotations.NullMarked;/a\import org.chromium.build.annotations.Nullable;' "$MENU_MEDIATOR"
grep -q 'org.chromium.chrome.browser.tabmodel.TabModelSelector' "$MENU_MEDIATOR" || \
    sed -i '/import org.chromium.chrome.browser.tab.TabLaunchType;/a\import org.chromium.chrome.browser.tabmodel.TabModelSelector;' "$MENU_MEDIATOR"
grep -q 'org.chromium.chrome.browser.ui.extensions.ExtensionActionPopupContents' "$MENU_MEDIATOR" || \
    sed -i '/import org.chromium.chrome.browser.ui.extensions.ExtensionActionContextMenuBridge;/a\import org.chromium.chrome.browser.ui.extensions.ExtensionActionPopupContents;' "$MENU_MEDIATOR"
grep -q 'org.chromium.components.embedder_support.contextmenu.ContextMenuPopulatorFactory' "$MENU_MEDIATOR" || \
    sed -i '/import org.chromium.components.embedder_support.util.UrlConstants;/i\import org.chromium.components.embedder_support.contextmenu.ContextMenuPopulatorFactory;' "$MENU_MEDIATOR"
grep -q 'org.chromium.content_public.browser.selection.SelectionDropdownMenuDelegate' "$MENU_MEDIATOR" || \
    sed -i '/import org.chromium.content_public.browser.LoadUrlParams;/a\import org.chromium.content_public.browser.selection.SelectionDropdownMenuDelegate;' "$MENU_MEDIATOR"
grep -q 'org.chromium.ui.base.WindowAndroid' "$MENU_MEDIATOR" || \
    sed -i '/import org.chromium.ui.base.PageTransition;/a\import org.chromium.ui.base.WindowAndroid;' "$MENU_MEDIATOR"
grep -q 'private final WindowAndroid mWindowAndroid;' "$MENU_MEDIATOR" || \
    sed -i '/private final Context mContext;/a\    private final WindowAndroid mWindowAndroid;\n    private final TabModelSelector mTabModelSelector;\n    private final @Nullable ContextMenuPopulatorFactory mContextMenuPopulatorFactory;\n    private final @Nullable SelectionDropdownMenuDelegate mSelectionDropdownMenuDelegate;' "$MENU_MEDIATOR"
grep -q 'mPendingActionAnchorView' "$MENU_MEDIATOR" || \
    sed -i '/private final TabCreator mTabCreator;/a\\n    private @Nullable View mPendingActionAnchorView;\n    private @Nullable ExtensionActionPopup mActivePopup;\n    private @Nullable String mActivePopupActionId;' "$MENU_MEDIATOR"
perl -0pi -e 's|(\n            WindowAndroid windowAndroid,\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,){2,}|\n            WindowAndroid windowAndroid,\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,|g' "$MENU_MEDIATOR"
grep -q 'WindowAndroid windowAndroid,' "$MENU_MEDIATOR" || \
    perl -0pi -e 's|(\n            TabCreator tabCreator,\n            ExtensionsToolbarBridge toolbarBridge,)|$1\n            WindowAndroid windowAndroid,\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,|' "$MENU_MEDIATOR"
perl -0pi -e 's|(\n        mWindowAndroid = windowAndroid;\n        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;){2,}|\n        mWindowAndroid = windowAndroid;\n        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;|g' "$MENU_MEDIATOR"
grep -q 'mWindowAndroid = windowAndroid;' "$MENU_MEDIATOR" || \
    perl -0pi -e 's|(\n        mActionModels = actionModels;\n        mContext = context;\n)|$1        mWindowAndroid = windowAndroid;\n        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;\n|' "$MENU_MEDIATOR"
perl -0pi -e 's|(mMenuBridge\.destroy\(\);\n    \})|closeActivePopup();\n        $1|' "$MENU_MEDIATOR"
perl -0pi -e 's|(?:\s*closeActivePopup\(\);\n)+(\s*mMenuBridge\.destroy\(\);)|\n        closeActivePopup();\n$1|' "$MENU_MEDIATOR"
sed -i 's|(view) -> mMenuBridge.executeAction(entry.id))|(view) -> onPrimaryActionClicked(view, entry.id))|' "$MENU_MEDIATOR"
sed -i 's|(view) -> openExtensionFromMenu(entry.id))|(view) -> onPrimaryActionClicked(view, entry.id))|' "$MENU_MEDIATOR"
sed -i 's|(view) -> openUrlFromMenu(UrlConstants.CHROME_EXTENSIONS_ID_URL + entry.id))|(view) -> onPrimaryActionClicked(view, entry.id))|' "$MENU_MEDIATOR"
sed -i 's|(view) -> openExtensionOptionsFromMenu(entry.id))|(view) -> onPrimaryActionClicked(view, entry.id))|' "$MENU_MEDIATOR"
perl -0pi -e 's|(\n  const raw_ptr<ExtensionsToolbarAndroid> toolbar_android_;\n)\n  // The platform-agnostic menu view model\.\n  std::unique_ptr<ExtensionsMenuViewModel> menu_model_;\n  base::ScopedObservation<ExtensionsMenuViewModel,\n                          ExtensionsMenuViewModel::Observer>\n      menu_model_observation_\{this\};\n\n  const base::android::ScopedJavaGlobalRef<jobject> java_object_;|$1\n  const base::android::ScopedJavaGlobalRef<jobject> java_object_;\n\n  // The platform-agnostic menu view model.\n  std::unique_ptr<ExtensionsMenuViewModel> menu_model_;\n  base::ScopedObservation<ExtensionsMenuViewModel,\n                          ExtensionsMenuViewModel::Observer>\n      menu_model_observation_{this};|' "$MENU_DELEGATE_H"
perl -0pi -e 's|: browser_\(browser\),\n      toolbar_android_\(toolbar_android\),\n      menu_model_\(std::make_unique<ExtensionsMenuViewModel>\(browser,\n                                                            /\*delegate=\*/this\)\),\n      java_object_\(java_object\) \{|: browser_(browser),\n      toolbar_android_(toolbar_android),\n      java_object_(java_object),\n      menu_model_(std::make_unique<ExtensionsMenuViewModel>(browser,\n                                                            /*delegate=*/this)) {|' "$MENU_DELEGATE_CC"
if ! grep -q 'private void onPrimaryActionClicked' "$MENU_MEDIATOR"; then
    sed -i '/private void openUrlFromMenu(String url) {/i\
    private void onPrimaryActionClicked(View anchorView, String extensionId) {\
        if (mActivePopup != null) {\
            boolean closeOnly = extensionId.equals(mActivePopupActionId);\
            closeActivePopup();\
            if (closeOnly) {\
                return;\
            }\
        }\
        mPendingActionAnchorView = anchorView;\
        mMenuBridge.executeAction(extensionId);\
    }\
\
    private void showActionPopup(String actionId, long nativeHostPtr) {\
        ExtensionActionPopupContents contents = ExtensionActionPopupContents.create(nativeHostPtr);\
        View anchorView = mPendingActionAnchorView;\
        mPendingActionAnchorView = null;\
        if (anchorView == null || !anchorView.isShown()) {\
            contents.destroy();\
            return;\
        }\
        Activity activity = mWindowAndroid.getActivity().get();\
        if (activity == null) {\
            contents.destroy();\
            return;\
        }\
        closeActivePopup();\
        mActivePopup =\
                new ExtensionActionPopup(\
                        activity,\
                        mWindowAndroid,\
                        anchorView,\
                        actionId,\
                        contents,\
                        mContextMenuPopulatorFactory,\
                        mSelectionDropdownMenuDelegate,\
                        mTabModelSelector);\
        mActivePopupActionId = actionId;\
        mActivePopup.loadInitialPage();\
        mActivePopup.addOnDismissListener(this::closeActivePopup);\
    }\
\
    private void showActionContextMenu(String actionId) {\
        ListMenuButton buttonView = findContextMenuButtonForPendingAction();\
        mPendingActionAnchorView = null;\
        if (buttonView != null) {\
            onContextMenuButtonClicked(buttonView, actionId);\
        }\
    }\
\
    private @Nullable ListMenuButton findContextMenuButtonForPendingAction() {\
        View current = mPendingActionAnchorView;\
        while (current != null) {\
            View button = current.findViewById(R.id.extensions_menu_item_context_menu);\
            if (button instanceof ListMenuButton) {\
                return (ListMenuButton) button;\
            }\
            if (!(current.getParent() instanceof View)) {\
                return null;\
            }\
            current = (View) current.getParent();\
        }\
        return null;\
    }\
\
    private void closeActivePopup() {\
        if (mActivePopup == null) {\
            return;\
        }\
        ExtensionActionPopup popup = mActivePopup;\
        mActivePopup = null;\
        mActivePopupActionId = null;\
        popup.destroy();\
    }\
\
' "$MENU_MEDIATOR"
fi
perl -0pi -e 's|\@Override\n    \@Override\n    public void onActionPopupRequested|@Override\n    public void onActionPopupRequested|' "$MENU_MEDIATOR"
grep -q 'public void onActionPopupRequested(String actionId, long nativeHostPtr)' "$MENU_MEDIATOR" || \
    perl -0pi -e 's|(\n    \@Override\n    public void onReady\(\) \{)|\n    \@Override\n    public void onActionPopupRequested(String actionId, long nativeHostPtr) {\n        showActionPopup(actionId, nativeHostPtr);\n    }\n\n    \@Override\n    public void onActionContextMenuRequested(String actionId) {\n        showActionContextMenu(actionId);\n    }\n\n    \@Override\n    public void hideActivePopup() {\n        closeActivePopup();\n    }\n\n    \@Override\n    public boolean hasActivePopup() {\n        return mActivePopup != null;\n    }\n$1|' "$MENU_MEDIATOR"
grep -q 'public void triggerPopup' "$BRIDGE" || \
    perl -0pi -e 's|(    public void onActionUpdated\(int actionIndex\) \{\n        mObserver\.onActionUpdated\(actionIndex\);\n    \}\n)|$1\n    \@CalledByNative\n    public void triggerPopup(\@JniType("std::string") String actionId, long nativeHostPtr) {\n        mObserver.onActionPopupRequested(actionId, nativeHostPtr);\n    }\n\n    \@CalledByNative\n    public void showContextMenu(\@JniType("std::string") String actionId) {\n        mObserver.onActionContextMenuRequested(actionId);\n    }\n\n    \@CalledByNative\n    public void hideActivePopup() {\n        mObserver.hideActivePopup();\n    }\n\n    \@CalledByNative\n    public boolean hasActivePopup() {\n        return mObserver.hasActivePopup();\n    }\n\n|' "$BRIDGE"
perl -0pi -e 's|    /\*\*\n    \@CalledByNative\n    public void triggerPopup\(\@JniType\("std::string"\) String actionId, long nativeHostPtr\) \{\n        mObserver\.onActionPopupRequested\(actionId, nativeHostPtr\);\n    \}\n\n    \@CalledByNative\n    public void showContextMenu\(\@JniType\("std::string"\) String actionId\) \{\n        mObserver\.onActionContextMenuRequested\(actionId\);\n    \}\n\n    \@CalledByNative\n    public void hideActivePopup\(\) \{\n        mObserver\.hideActivePopup\(\);\n    \}\n\n    \@CalledByNative\n    public boolean hasActivePopup\(\) \{\n        return mObserver\.hasActivePopup\(\);\n    \}\n\n\n     \* Callback from native indicating that an extension has been updated\.|    /**\n     * Callback from native indicating that an extension has been updated.|' "$BRIDGE"
perl -0pi -e 's|\@CalledByNative\n    \@CalledByNative\n    public void triggerPopup|@CalledByNative\n    public void triggerPopup|' "$BRIDGE"
grep -q 'void onActionPopupRequested(String actionId, long nativeHostPtr);' "$BRIDGE" || \
    sed -i '/void onActionUpdated(int actionIndex);/a\\n        /** Called when native created a popup host for a menu action. */\n        void onActionPopupRequested(String actionId, long nativeHostPtr);\n\n        /** Called when native wants to show fallback context menu for a menu action. */\n        void onActionContextMenuRequested(String actionId);\n\n        /** Called when active popup should be hidden. */\n        void hideActivePopup();\n\n        /** Returns whether there is an active popup. */\n        boolean hasActivePopup();' "$BRIDGE"
grep -q 'base/android/scoped_java_ref.h' "$ACTION_DELEGATE_H" || \
    sed -i '/#include "base\/memory\/raw_ptr.h"/i\#include "base/android/scoped_java_ref.h"' "$ACTION_DELEGATE_H"
grep -q 'java_menu_object' "$ACTION_DELEGATE_H" || \
    sed -i '/extensions::ExtensionsToolbarAndroid\* toolbar_android);/a\  ExtensionActionDelegateAndroid(\n      BrowserWindowInterface* browser,\n      const ToolbarActionsModel::ActionId& action_id,\n      extensions::ExtensionsToolbarAndroid* toolbar_android,\n      const base::android::JavaRef<jobject>& java_menu_object);' "$ACTION_DELEGATE_H"
grep -q 'java_menu_object_' "$ACTION_DELEGATE_H" || \
    sed -i '/const raw_ptr<extensions::ExtensionsToolbarAndroid> toolbar_android_;/a\\n  // Optional Java menu bridge used when a popup was requested from the extensions menu.\n  const base::android::ScopedJavaGlobalRef<jobject> java_menu_object_;' "$ACTION_DELEGATE_H"
grep -q '#include "base/android/jni_android.h"' "$ACTION_DELEGATE_CC" || \
    sed -i '/#include <utility>/a\\n#include "base/android/jni_android.h"' "$ACTION_DELEGATE_CC"
grep -q '#include <cstdint>' "$ACTION_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/ui\/android\/extensions\/extension_action_delegate_android.h"/a\\n#include <cstdint>' "$ACTION_DELEGATE_CC"
perl -0pi -e 's~#pragma clang diagnostic push\n#pragma clang diagnostic ignored "-Wunused-function"\n#include "chrome/browser/ui/android/extensions/jni_headers/ExtensionsMenuBridge_jni.h"\n#pragma clang diagnostic pop~#include "chrome/browser/ui/android/extensions/jni_headers/ExtensionsMenuBridge_jni.h"~g; s~\n?DEFINE_JNI_ExtensionsMenuBridge\(\);?\n~\n~g' "$ACTION_DELEGATE_CC"
grep -q 'ExtensionsMenuBridge_jni.h' "$ACTION_DELEGATE_CC" || \
    perl -0pi -e 's~(#include "chrome/browser/ui/extensions/extension_action_view_model.h"\n)~$1\n#include "chrome/browser/ui/android/extensions/jni_headers/ExtensionsMenuBridge_jni.h"\n~' "$ACTION_DELEGATE_CC"
perl -0pi -e 's~(?:#pragma clang diagnostic ignored "-Wunused-function"\n)*(#include "chrome/browser/ui/android/extensions/jni_headers/ExtensionsMenuBridge_jni.h"\n)~#pragma clang diagnostic ignored "-Wunused-function"\n$1~g' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|(ExtensionActionDelegateAndroid::ExtensionActionDelegateAndroid\(\n    BrowserWindowInterface\* browser,\n    const ToolbarActionsModel::ActionId& action_id,\n    extensions::ExtensionsToolbarAndroid\* toolbar_android,\n    const base::android::JavaRef<jobject>& java_menu_object\)\n    : browser_\(browser\),\n      action_id_\(action_id\),\n      toolbar_android_\(toolbar_android\),\n      java_menu_object_\(java_menu_object\) \{\}\n\n){2,}|$1|g' "$ACTION_DELEGATE_CC"
grep -q 'const base::android::JavaRef<jobject>& java_menu_object)' "$ACTION_DELEGATE_CC" || \
    perl -0pi -e 's|ExtensionActionDelegateAndroid::ExtensionActionDelegateAndroid\(\n    BrowserWindowInterface\* browser,\n    const ToolbarActionsModel::ActionId& action_id,\n    extensions::ExtensionsToolbarAndroid\* toolbar_android\)\n    : browser_\(browser\),\n      action_id_\(action_id\),\n      toolbar_android_\(toolbar_android\) \{\}|ExtensionActionDelegateAndroid::ExtensionActionDelegateAndroid(\n    BrowserWindowInterface* browser,\n    const ToolbarActionsModel::ActionId& action_id,\n    extensions::ExtensionsToolbarAndroid* toolbar_android)\n    : browser_(browser),\n      action_id_(action_id),\n      toolbar_android_(toolbar_android) {}\n\nExtensionActionDelegateAndroid::ExtensionActionDelegateAndroid(\n    BrowserWindowInterface* browser,\n    const ToolbarActionsModel::ActionId& action_id,\n    extensions::ExtensionsToolbarAndroid* toolbar_android,\n    const base::android::JavaRef<jobject>& java_menu_object)\n    : browser_(browser),\n      action_id_(action_id),\n      toolbar_android_(toolbar_android),\n      java_menu_object_(java_menu_object) {}|' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|bool ExtensionActionDelegateAndroid::IsShowingPopup\(\) const \{\n  return toolbar_android_->HasActivePopup\(\);\n\}|bool ExtensionActionDelegateAndroid::IsShowingPopup() const {\n  if (!java_menu_object_.is_null()) {\n    return extensions::Java_ExtensionsMenuBridge_hasActivePopup(\n        base::android::AttachCurrentThread(), java_menu_object_);\n  }\n  return toolbar_android_->HasActivePopup();\n}|' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|void ExtensionActionDelegateAndroid::HidePopup\(\) \{\n  toolbar_android_->HideActivePopup\(\);\n\}|void ExtensionActionDelegateAndroid::HidePopup() {\n  if (!java_menu_object_.is_null()) {\n    extensions::Java_ExtensionsMenuBridge_hideActivePopup(\n        base::android::AttachCurrentThread(), java_menu_object_);\n    return;\n  }\n  toolbar_android_->HideActivePopup();\n}|' "$ACTION_DELEGATE_CC"
grep -q 'SetAndroidExtensionPopupWebContents(nullptr)' "$ACTION_DELEGATE_CC" || \
    perl -0pi -e 's|(void ExtensionActionDelegateAndroid::HidePopup\(\) \{\n)|$1#if BUILDFLAG(IS_ANDROID)\n  extensions::ExtensionTabUtil::SetAndroidExtensionPopupWebContents(nullptr);\n#endif\n|s' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|void ExtensionActionDelegateAndroid::TriggerPopup\(\n    std::unique_ptr<extensions::ExtensionViewHost> host,\n    PopupShowAction show_action,\n    bool by_user,\n    ShowPopupCallback callback\) \{\n  toolbar_android_->TriggerPopup\(action_id_, std::move\(host\)\);\n\}|void ExtensionActionDelegateAndroid::TriggerPopup(\n    std::unique_ptr<extensions::ExtensionViewHost> host,\n    PopupShowAction show_action,\n    bool by_user,\n    ShowPopupCallback callback) {\n  if (!java_menu_object_.is_null()) {\n    extensions::Java_ExtensionsMenuBridge_triggerPopup(\n        base::android::AttachCurrentThread(), java_menu_object_, action_id_,\n        reinterpret_cast<int64_t>(host.release()));\n    return;\n  }\n  toolbar_android_->TriggerPopup(action_id_, std::move(host));\n}|' "$ACTION_DELEGATE_CC"
grep -q 'active_web_contents = nullptr' "$ACTION_DELEGATE_CC" || \
    perl -0pi -e 's|(void ExtensionActionDelegateAndroid::TriggerPopup\(\n    std::unique_ptr<extensions::ExtensionViewHost> host,\n    PopupShowAction show_action,\n    bool by_user,\n    ShowPopupCallback callback\) \{\n)|$1#if BUILDFLAG(IS_ANDROID)\n  content::WebContents* active_web_contents = nullptr;\n  if (!java_menu_object_.is_null() && browser_) {\n    active_web_contents =\n        extensions::ExtensionTabUtil::GetAndroidExtensionPopupWebContents(\n            browser_->GetProfile(), /*include_incognito=*/true);\n  }\n  if (!active_web_contents && browser_) {\n    TabListInterface* tab_list = TabListInterface::From(browser_);\n    tabs::TabInterface* active_tab =\n        tab_list ? tab_list->GetActiveTab() : nullptr;\n    active_web_contents = active_tab ? active_tab->GetContents() : nullptr;\n  }\n  extensions::ExtensionTabUtil::SetAndroidExtensionPopupWebContents(\n      active_web_contents);\n#endif\n|s' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|#if BUILDFLAG\(IS_ANDROID\)\n  content::WebContents\* active_web_contents = nullptr;\n  if \(browser_\) \{\n    TabListInterface\* tab_list = TabListInterface::From\(browser_\);\n    tabs::TabInterface\* active_tab =\n        tab_list \? tab_list->GetActiveTab\(\) : nullptr;\n    active_web_contents = active_tab \? active_tab->GetContents\(\) : nullptr;\n  \}\n  extensions::ExtensionTabUtil::SetAndroidExtensionPopupWebContents\(\n      active_web_contents\);\n#endif|#if BUILDFLAG(IS_ANDROID)\n  content::WebContents* active_web_contents = nullptr;\n  if (!java_menu_object_.is_null() && browser_) {\n    active_web_contents =\n        extensions::ExtensionTabUtil::GetAndroidExtensionPopupWebContents(\n            browser_->GetProfile(), /*include_incognito=*/true);\n  }\n  if (!active_web_contents && browser_) {\n    TabListInterface* tab_list = TabListInterface::From(browser_);\n    tabs::TabInterface* active_tab =\n        tab_list ? tab_list->GetActiveTab() : nullptr;\n    active_web_contents = active_tab ? active_tab->GetContents() : nullptr;\n  }\n  extensions::ExtensionTabUtil::SetAndroidExtensionPopupWebContents(\n      active_web_contents);\n#endif|s' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|(#if BUILDFLAG\(IS_ANDROID\)\n  content::WebContents\* active_web_contents = nullptr;\n  if \(!java_menu_object_\.is_null\(\) && browser_\) \{\n    active_web_contents =\n        extensions::ExtensionTabUtil::GetAndroidExtensionPopupWebContents\(\n            browser_->GetProfile\(\), /\*include_incognito=\*/true\);\n  \}\n  if \(!active_web_contents && browser_\) \{\n    TabListInterface\* tab_list = TabListInterface::From\(browser_\);\n    tabs::TabInterface\* active_tab =\n        tab_list \? tab_list->GetActiveTab\(\) : nullptr;\n    active_web_contents = active_tab \? active_tab->GetContents\(\) : nullptr;\n  \}\n  extensions::ExtensionTabUtil::SetAndroidExtensionPopupWebContents\(\n      active_web_contents\);\n#endif\n){2,}|$1|g' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|void ExtensionActionDelegateAndroid::ShowContextMenuAsFallback\(\) \{\n  toolbar_android_->ShowContextMenu\(action_id_\);\n\}|void ExtensionActionDelegateAndroid::ShowContextMenuAsFallback() {\n  if (!java_menu_object_.is_null()) {\n    extensions::Java_ExtensionsMenuBridge_showContextMenu(\n        base::android::AttachCurrentThread(), java_menu_object_, action_id_);\n    return;\n  }\n  toolbar_android_->ShowContextMenu(action_id_);\n}|' "$ACTION_DELEGATE_CC"
perl -0pi -e 's~\bJava_ExtensionsMenuBridge_(hasActivePopup|hideActivePopup|triggerPopup|showContextMenu)\b~extensions::Java_ExtensionsMenuBridge_$1~g; s~extensions::extensions::Java_ExtensionsMenuBridge_~extensions::Java_ExtensionsMenuBridge_~g' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|void ExtensionActionDelegateAndroid::CloseExtensionsMenuIfOpen\(\) \{\n  toolbar_android_->CloseExtensionsMenuIfOpen\(\);\n\}|void ExtensionActionDelegateAndroid::CloseExtensionsMenuIfOpen() {\n  if (!java_menu_object_.is_null()) {\n    return;\n  }\n  toolbar_android_->CloseExtensionsMenuIfOpen();\n}|' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|std::make_unique<ExtensionActionDelegateAndroid>\(browser_, extension_id,\n                                                       toolbar_android_\)|std::make_unique<ExtensionActionDelegateAndroid>(browser_, extension_id,\n                                                       toolbar_android_,\n                                                       java_object_)|' "$MENU_DELEGATE_CC"

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

# Show extension-provided per-tab action titles in the Android extensions
# menu. Proxy managers such as SwitchyOmega/ZeroOmega update this title with
# the current page's matched proxy profile, while the stock Android menu only
# displayed the static extension name.
grep -q 'build/build_config.h' "$MENU_VIEW_MODEL" || \
    sed -i '/#include "base\/metrics\/user_metrics_action.h"/a\#include "build/build_config.h"' "$MENU_VIEW_MODEL"
perl -0pi -e 's|  ExtensionsMenuViewModel::ControlState button_state;\n  button_state\.text = action_model->GetActionName\(\);|  ExtensionsMenuViewModel::ControlState button_state;\n#if BUILDFLAG(IS_ANDROID)\n  std::u16string action_title =\n      web_contents ? action_model->GetActionTitle(web_contents)\n                   : std::u16string();\n  button_state.text = action_title.empty() ? action_model->GetActionName()\n                                           : action_title;\n#else\n  button_state.text = action_model->GetActionName();\n#endif|' "$MENU_VIEW_MODEL"

# Use the current Java tab when the Android extensions menu asks native for
# action state. The platform-agnostic menu model can otherwise resolve the
# active WebContents from the regular browser window while the visible tab is
# incognito, which makes per-tab action titles/icons (SwitchyOmega status) show
# the normal tab instead of the current incognito page.
grep -q 'org.chromium.content_public.browser.WebContents;' "$BRIDGE" || \
    sed -i '/import org.chromium.chrome.browser.ui.browser_window.ChromeAndroidTask;/a\import org.chromium.content_public.browser.WebContents;' "$BRIDGE"
perl -0pi -e 's|public void executeAction\(String extensionId\) \{\n        ExtensionsMenuBridgeJni\.get\(\)\n                \.executeAction\(mNativeExtensionsMenuDelegateAndroid, extensionId\);\n    \}|public void executeAction(String extensionId) {\n        executeAction(extensionId, null);\n    }\n\n    public void executeAction(String extensionId, \@Nullable WebContents webContents) {\n        ExtensionsMenuBridgeJni.get()\n                .executeAction(mNativeExtensionsMenuDelegateAndroid, extensionId, webContents);\n    }|' "$BRIDGE"
perl -0pi -e 's|public \@Nullable Bitmap getActionIcon\(int actionIndex\) \{\n        return ExtensionsMenuBridgeJni\.get\(\)\n                \.getActionIcon\(mNativeExtensionsMenuDelegateAndroid, actionIndex\);\n    \}|public \@Nullable Bitmap getActionIcon(int actionIndex) {\n        return getActionIcon(actionIndex, null);\n    }\n\n    public \@Nullable Bitmap getActionIcon(int actionIndex, \@Nullable WebContents webContents) {\n        return ExtensionsMenuBridgeJni.get()\n                .getActionIcon(mNativeExtensionsMenuDelegateAndroid, actionIndex, webContents);\n    }|' "$BRIDGE"
perl -0pi -e 's|public List<ExtensionsMenuTypes\.MenuEntryState> getMenuEntries\(\) \{\n        return ExtensionsMenuBridgeJni\.get\(\)\.getMenuEntries\(mNativeExtensionsMenuDelegateAndroid\);\n    \}|public List<ExtensionsMenuTypes.MenuEntryState> getMenuEntries() {\n        return getMenuEntries(null);\n    }\n\n    public List<ExtensionsMenuTypes.MenuEntryState> getMenuEntries(\n            \@Nullable WebContents webContents) {\n        return ExtensionsMenuBridgeJni.get()\n                .getMenuEntries(mNativeExtensionsMenuDelegateAndroid, webContents);\n    }|' "$BRIDGE"
perl -0pi -e 's|public ExtensionsMenuTypes\.MenuEntryState getMenuEntry\(int actionIndex\) \{\n        return ExtensionsMenuBridgeJni\.get\(\)\n                \.getMenuEntry\(mNativeExtensionsMenuDelegateAndroid, actionIndex\);\n    \}|public ExtensionsMenuTypes.MenuEntryState getMenuEntry(int actionIndex) {\n        return getMenuEntry(actionIndex, null);\n    }\n\n    public ExtensionsMenuTypes.MenuEntryState getMenuEntry(\n            int actionIndex, \@Nullable WebContents webContents) {\n        return ExtensionsMenuBridgeJni.get()\n                .getMenuEntry(mNativeExtensionsMenuDelegateAndroid, actionIndex, webContents);\n    }|' "$BRIDGE"
perl -0pi -e 's|\@Nullable Bitmap getActionIcon\(long nativeExtensionsMenuDelegateAndroid, int actionIndex\);|\@Nullable Bitmap getActionIcon(\n                long nativeExtensionsMenuDelegateAndroid,\n                int actionIndex,\n                \@Nullable \@JniType("content::WebContents*") WebContents webContents);|' "$BRIDGE"
perl -0pi -e 's|void executeAction\(\n                long nativeExtensionsMenuDelegateAndroid,\n                \@JniType\("std::string"\) String extensionId\);|void executeAction(\n                long nativeExtensionsMenuDelegateAndroid,\n                \@JniType("std::string") String extensionId,\n                \@Nullable \@JniType("content::WebContents*") WebContents webContents);|' "$BRIDGE"
perl -0pi -e 's|List<ExtensionsMenuTypes\.MenuEntryState> getMenuEntries\(\n                long nativeExtensionsMenuDelegateAndroid\);|List<ExtensionsMenuTypes.MenuEntryState> getMenuEntries(\n                long nativeExtensionsMenuDelegateAndroid,\n                \@Nullable \@JniType("content::WebContents*") WebContents webContents);|' "$BRIDGE"
perl -0pi -e 's|ExtensionsMenuTypes\.MenuEntryState getMenuEntry\(\n                long nativeExtensionsMenuDelegateAndroid, int actionIndex\);|ExtensionsMenuTypes.MenuEntryState getMenuEntry(\n                long nativeExtensionsMenuDelegateAndroid,\n                int actionIndex,\n                \@Nullable \@JniType("content::WebContents*") WebContents webContents);|' "$BRIDGE"

grep -q 'org.chromium.build.annotations.Nullable' "$MENU_MEDIATOR" || \
    sed -i '/import org.chromium.build.annotations.NullMarked;/a\import org.chromium.build.annotations.Nullable;' "$MENU_MEDIATOR"
# dedupe duplicate getCurrentWebContents methods from older hotfix runs
python3 - "$MENU_MEDIATOR" <<'PYCODE'
from pathlib import Path
import sys

path = Path(sys.argv[1])
lines = path.read_text().splitlines(keepends=True)
starts = [
    i for i, line in enumerate(lines)
    if line.strip() == "private @Nullable WebContents getCurrentWebContents() {"
]
if len(starts) > 1:
    ranges = []
    for start in starts:
        depth = 0
        end = None
        for idx in range(start, len(lines)):
            depth += lines[idx].count("{") - lines[idx].count("}")
            if idx > start and depth <= 0:
                end = idx + 1
                break
        if end is not None:
            ranges.append((start, end))
    for start, end in reversed(ranges[:-1]):
        del lines[start:end]
    path.write_text("".join(lines))
PYCODE
grep -q 'org.chromium.chrome.browser.tabmodel.TabModel;' "$MENU_MEDIATOR" || sed -i '/import org.chromium.chrome.browser.tabmodel.TabModelSelector;/a\import org.chromium.chrome.browser.tabmodel.TabModel;' "$MENU_MEDIATOR"
grep -q 'private @Nullable WebContents getCurrentWebContents()' "$MENU_MEDIATOR" || \
    sed -i '/private @ExtensionsMenuProperties.Page int getCurrentPage()/i\
    private @Nullable WebContents getCurrentWebContents() {\
        Tab currentTab = null;\
        if (mTabModelSelector != null) {\
            TabModel incognitoModel = mTabModelSelector.getModel(true);\
            Tab incognitoTab = incognitoModel.getCurrentTabSupplier().get();\
            if (incognitoTab != null && incognitoTab.getWebContents() != null) {\
                currentTab = incognitoTab;\
            }\
            if (currentTab == null) currentTab = mTabModelSelector.getCurrentTab();\
        }\
        if (currentTab == null) currentTab = mCurrentTabSupplier.get();\
        return currentTab != null ? currentTab.getWebContents() : null;\
    }\
\
' "$MENU_MEDIATOR"
perl -0pi -e 's|private \@Nullable WebContents getCurrentWebContents\(\) \{\n        Tab currentTab = mCurrentTabSupplier\.get\(\);\n        return currentTab != null \? currentTab\.getWebContents\(\) : null;\n    \}|private @Nullable WebContents getCurrentWebContents() {\n        Tab currentTab = mTabModelSelector != null ? mTabModelSelector.getCurrentTab() : null;\n        if (currentTab == null) currentTab = mCurrentTabSupplier.get();\n        return currentTab != null ? currentTab.getWebContents() : null;\n    }|' "$MENU_MEDIATOR"
perl -0pi -e 's|private @Nullable WebContents getCurrentWebContents\(\) {\n        Tab currentTab = mTabModelSelector != null \? mTabModelSelector\.getCurrentTab\(\) : null;\n        if \(currentTab == null\) currentTab = mCurrentTabSupplier\.get\(\);\n        return currentTab != null \? currentTab\.getWebContents\(\) : null;\n    }|private @Nullable WebContents getCurrentWebContents() {\n        Tab currentTab = null;\n        if (mTabModelSelector != null) {\n            TabModel incognitoModel = mTabModelSelector.getModel(true);\n            Tab incognitoTab = incognitoModel.getCurrentTabSupplier().get();\n            if (incognitoTab != null\n                    \&\& (mTabModelSelector.isOffTheRecordModelSelected()\n                            || mTabModelSelector.isIncognitoBrandedModelSelected()\n                            || incognitoModel.isActiveModel()\n                            || incognitoTab.isUserInteractable()\n                            || incognitoTab.isActivated())) {\n                currentTab = incognitoTab;\n            }\n            if (currentTab == null) currentTab = mTabModelSelector.getCurrentTab();\n        }\n        if (currentTab == null) currentTab = mCurrentTabSupplier.get();\n        return currentTab != null ? currentTab.getWebContents() : null;\n    }|' "$MENU_MEDIATOR"
perl -0pi -e 's|private @Nullable WebContents getCurrentWebContents\(\) {
        Tab currentTab = null;
        if \(mTabModelSelector != null\) {
            TabModel incognitoModel = mTabModelSelector.getModel\(true\);
            Tab incognitoTab = incognitoModel.getCurrentTabSupplier\(\).get\(\);
            if \(incognitoTab != null
                    \&\& \(mTabModelSelector.isOffTheRecordModelSelected\(\)
                            \|\| mTabModelSelector.isIncognitoBrandedModelSelected\(\)
                            \|\| incognitoModel.isActiveModel\(\)
                            \|\| incognitoTab.isUserInteractable\(\)
                            \|\| incognitoTab.isActivated\(\)\)\) {
                currentTab = incognitoTab;
            }
            if \(currentTab == null\) currentTab = mTabModelSelector.getCurrentTab\(\);
        }
        if \(currentTab == null\) currentTab = mCurrentTabSupplier.get\(\);
        return currentTab != null \? currentTab.getWebContents\(\) : null;
    }|private @Nullable WebContents getCurrentWebContents() {        Tab currentTab = null;        if (mTabModelSelector != null) {            TabModel incognitoModel = mTabModelSelector.getModel(true);            Tab incognitoTab = incognitoModel.getCurrentTabSupplier().get();            if (incognitoTab != null \&\& incognitoTab.getWebContents() != null) {                currentTab = incognitoTab;            }            if (currentTab == null) currentTab = mTabModelSelector.getCurrentTab();        }        if (currentTab == null) currentTab = mCurrentTabSupplier.get();        return currentTab != null ? currentTab.getWebContents() : null;    }|' "$MENU_MEDIATOR"
# rebuild getCurrentWebContents once after all legacy migrations
python3 - "$MENU_MEDIATOR" <<'PYCODE'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
needle = "private @Nullable WebContents getCurrentWebContents() {"
while True:
    pos = text.find(needle)
    if pos < 0:
        break
    start = text.rfind("\n", 0, pos)
    start = 0 if start < 0 else start
    brace = text.find("{", pos)
    depth = 0
    end = None
    for idx in range(brace, len(text)):
        if text[idx] == "{":
            depth += 1
        elif text[idx] == "}":
            depth -= 1
            if depth == 0:
                end = idx + 1
                while end < len(text) and text[end] in " \t\r\n":
                    end += 1
                break
    if end is None:
        break
    text = text[:start] + "\n" + text[end:]
helper = "\n".join([
    "",
    "    private @Nullable WebContents getCurrentWebContents() {",
    "        Tab currentTab = null;",
    "        if (mTabModelSelector != null) {",
    "            TabModel incognitoModel = mTabModelSelector.getModel(true);",
    "            Tab incognitoTab = incognitoModel.getCurrentTabSupplier().get();",
    "            if (incognitoTab != null && incognitoTab.getWebContents() != null) {",
    "                currentTab = incognitoTab;",
    "            }",
    "            if (currentTab == null) currentTab = mTabModelSelector.getCurrentTab();",
    "        }",
    "        if (currentTab == null) currentTab = mCurrentTabSupplier.get();",
    "        return currentTab != null ? currentTab.getWebContents() : null;",
    "    }",
    "",
    "",
])
marker = "    private @ExtensionsMenuProperties.Page int getCurrentPage()"
if marker not in text:
    raise SystemExit("getCurrentPage marker not found")
text = text.replace(marker, helper + marker, 1)
path.write_text(text)
PYCODE
sed -i 's|mMenuBridge.getMenuEntry(actionIndex)|mMenuBridge.getMenuEntry(actionIndex, getCurrentWebContents())|g' "$MENU_MEDIATOR"
sed -i 's|mMenuBridge.getMenuEntry(newIndex)|mMenuBridge.getMenuEntry(newIndex, getCurrentWebContents())|g' "$MENU_MEDIATOR"
sed -i 's|mMenuBridge.getActionIcon(actionIndex)|mMenuBridge.getActionIcon(actionIndex, getCurrentWebContents())|g' "$MENU_MEDIATOR"
sed -i 's|mMenuBridge.getMenuEntries()|mMenuBridge.getMenuEntries(getCurrentWebContents())|g' "$MENU_MEDIATOR"
perl -0pi -e 's|mMenuBridge\.executeAction\(extensionId\);|mMenuBridge.executeAction(extensionId, getCurrentWebContents());|g' "$MENU_MEDIATOR"
perl -0pi -e 's|mMenuBridge\.executeAction\(entry\.id\)(?!,)|mMenuBridge.executeAction(entry.id, getCurrentWebContents())|g' "$MENU_MEDIATOR"

grep -q 'namespace content {' "$MENU_DELEGATE_H" || \
    sed -i '/namespace extensions {/i\
namespace content {\
class WebContents;\
}  // namespace content\
\
' "$MENU_DELEGATE_H"
perl -0pi -e 's|void ExecuteAction\(JNIEnv\* env, const extensions::ExtensionId& extension_id\);|void ExecuteAction(JNIEnv* env,\n                     const extensions::ExtensionId& extension_id,\n                     content::WebContents* web_contents);|' "$MENU_DELEGATE_H"
perl -0pi -e 's|base::android::ScopedJavaLocalRef<jobject> GetActionIcon\(JNIEnv\* env,\n                                                           int action_index\);|base::android::ScopedJavaLocalRef<jobject> GetActionIcon(\n      JNIEnv* env,\n      int action_index,\n      content::WebContents* web_contents);|' "$MENU_DELEGATE_H"
perl -0pi -e 's|base::android::ScopedJavaLocalRef<jobject> GetMenuEntry\(JNIEnv\* env,\n                                                          int action_index\);|base::android::ScopedJavaLocalRef<jobject> GetMenuEntry(\n      JNIEnv* env,\n      int action_index,\n      content::WebContents* web_contents);|' "$MENU_DELEGATE_H"
perl -0pi -e 's|std::vector<base::android::ScopedJavaLocalRef<jobject>> GetMenuEntries\(\n      JNIEnv\* env\);|std::vector<base::android::ScopedJavaLocalRef<jobject>> GetMenuEntries(\n      JNIEnv* env,\n      content::WebContents* web_contents);|' "$MENU_DELEGATE_H"

grep -q 'chrome/browser/tab_list/tab_list_interface.h' "$MENU_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/ui\/android\/extensions\/extension_action_delegate_android.h"/a\#include "chrome/browser/tab_list/tab_list_interface.h"' "$MENU_DELEGATE_CC"
grep -q 'chrome/browser/ui/toolbar/toolbar_action_view_model.h' "$MENU_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/ui\/extensions\/extensions_menu_view_model.h"/a\#include "chrome/browser/ui/toolbar/toolbar_action_view_model.h"' "$MENU_DELEGATE_CC"
grep -q 'components/tabs/public/tab_interface.h' "$MENU_DELEGATE_CC" || \
    sed -i '/#include "chrome\/browser\/ui\/extensions\/extensions_menu_view_model.h"/a\#include "components/tabs/public/tab_interface.h"' "$MENU_DELEGATE_CC"
grep -q 'extensions/browser/extension_registry.h' "$MENU_DELEGATE_CC" || \
    sed -i '/#include "components\/tabs\/public\/tab_interface.h"/a\#include "extensions/browser/extension_registry.h"' "$MENU_DELEGATE_CC"
perl -0pi -e 's|void ExtensionsMenuDelegateAndroid::ExecuteAction\(\n    JNIEnv\* env,\n    const extensions::ExtensionId& extension_id\) \{\n  menu_model_->ExecuteAction\(extension_id\);\n\}|void ExtensionsMenuDelegateAndroid::ExecuteAction(\n    JNIEnv* env,\n    const extensions::ExtensionId& extension_id,\n    content::WebContents* web_contents) {\n  if (web_contents) {\n    tabs::TabInterface* tab =\n        tabs::TabInterface::MaybeGetFromContents(web_contents);\n    BrowserWindowInterface* action_browser =\n        tab ? tab->GetBrowserWindowInterface() : nullptr;\n    TabListInterface* tab_list =\n        action_browser ? TabListInterface::From(action_browser) : nullptr;\n    extensions::ExtensionRegistry* registry =\n        action_browser\n            ? extensions::ExtensionRegistry::Get(action_browser->GetProfile())\n            : nullptr;\n    if (tab_list \&\& registry \&\&\n        registry->enabled_extensions().Contains(extension_id)) {\n      tab_list->ActivateTab(tab->GetHandle());\n      auto action_model = ExtensionActionViewModel::Create(\n          extension_id, action_browser,\n          std::make_unique<ExtensionActionDelegateAndroid>(\n              action_browser, extension_id, toolbar_android_, java_object_));\n      action_model->ExecuteUserAction(\n          ToolbarActionViewModel::InvocationSource::kMenuEntry);\n      return;\n    }\n  }\n\n  menu_model_->ExecuteAction(extension_id);\n}|' "$MENU_DELEGATE_CC"
perl -0pi -e 's|ScopedJavaLocalRef<jobject> ExtensionsMenuDelegateAndroid::GetActionIcon\(\n    JNIEnv\* env,\n    int action_index\) \{\n  ui::ImageModel icon_model =\n      menu_model_->GetActionIcon\(action_index, kActionIconSize\);\n  return ConvertToJavaBitmap\(icon_model\);\n\}|ScopedJavaLocalRef<jobject> ExtensionsMenuDelegateAndroid::GetActionIcon(\n    JNIEnv* env,\n    int action_index,\n    content::WebContents* web_contents) {\n  if (web_contents) {\n    const auto\& action_models = menu_model_->action_models();\n    CHECK_GE(action_index, 0);\n    CHECK_LT(static_cast<size_t>(action_index), action_models.size());\n    return ConvertToJavaBitmap(\n        action_models[action_index]->GetIcon(web_contents, kActionIconSize));\n  }\n\n  ui::ImageModel icon_model =\n      menu_model_->GetActionIcon(action_index, kActionIconSize);\n  return ConvertToJavaBitmap(icon_model);\n}|' "$MENU_DELEGATE_CC"
perl -0pi -e 's|ScopedJavaLocalRef<jobject> ExtensionsMenuDelegateAndroid::GetMenuEntry\(\n    JNIEnv\* env,\n    int action_index\) \{|ScopedJavaLocalRef<jobject> ExtensionsMenuDelegateAndroid::GetMenuEntry(\n    JNIEnv* env,\n    int action_index,\n    content::WebContents* web_contents) {|' "$MENU_DELEGATE_CC"
grep -q 'action_model->GetActionTitle(web_contents)' "$MENU_DELEGATE_CC" || \
    perl -0pi -e 's|  ExtensionsMenuViewModel::MenuEntryState state =\n      menu_model_->GetMenuEntryState\(id, kActionIconSize\);\n|  ExtensionsMenuViewModel::MenuEntryState state =\n      menu_model_->GetMenuEntryState(id, kActionIconSize);\n  if (web_contents) {\n    std::u16string action_title = action_model->GetActionTitle(web_contents);\n    if (!action_title.empty()) {\n      state.action_button.text = action_title;\n    }\n    state.action_button.tooltip_text = action_model->GetTooltip(web_contents);\n    state.action_button.status =\n        action_model->IsEnabled(web_contents)\n            ? ExtensionsMenuViewModel::ControlState::Status::kEnabled\n            : ExtensionsMenuViewModel::ControlState::Status::kDisabled;\n    state.action_button.icon =\n        action_model->GetIcon(web_contents, kActionIconSize);\n    state.origin = web_contents->GetPrimaryMainFrame()->GetLastCommittedOrigin();\n  }\n|' "$MENU_DELEGATE_CC"
perl -0pi -e 's|std::u16string action_title = action_model->GetActionTitle\(web_contents\);\n    state\.action_button\.text = action_title\.empty\(\)\n                                   \? action_model->GetActionName\(\)\n                                   : action_title;|std::u16string action_title = action_model->GetActionTitle(web_contents);\n    if (!action_title.empty()) {\n      state.action_button.text = action_title;\n    }|' "$MENU_DELEGATE_CC"
perl -0pi -e 's|ExtensionsMenuDelegateAndroid::GetMenuEntries\(JNIEnv\* env\) \{|ExtensionsMenuDelegateAndroid::GetMenuEntries(\n    JNIEnv* env,\n    content::WebContents* web_contents) {|' "$MENU_DELEGATE_CC"
sed -i 's|GetMenuEntry(env, i)|GetMenuEntry(env, i, web_contents)|g' "$MENU_DELEGATE_CC"

# Android does not expose Chrome's desktop "Allow in incognito" extension
# toggle. Treat installed extensions as incognito-enabled so proxy extensions
# such as SwitchyOmega can register controlled proxy prefs for OTR profiles.
perl -0pi -e 's|bool ExtensionPrefs::IsIncognitoEnabled\(const ExtensionId& extension_id\) const \{\n  return ReadPrefAsBooleanAndReturn\(extension_id, kPrefIncognitoEnabled\);\n\}|bool ExtensionPrefs::IsIncognitoEnabled(const ExtensionId& extension_id) const {\n#if BUILDFLAG(IS_ANDROID)\n  return true;\n#else\n  return ReadPrefAsBooleanAndReturn(extension_id, kPrefIncognitoEnabled);\n#endif\n}|' "$EXTENSION_PREFS"
perl -0pi -e 's|void ExtensionPrefs::SetIsIncognitoEnabled\(const ExtensionId& extension_id,\n                                           bool enabled\) \{\n  UpdateExtensionPref\(extension_id, kPrefIncognitoEnabled,\n                      base::Value\(enabled\)\);\n  extension_pref_value_map_->SetExtensionIncognitoState\(extension_id, enabled\);\n\}|void ExtensionPrefs::SetIsIncognitoEnabled(const ExtensionId& extension_id,\n                                           bool enabled) {\n#if BUILDFLAG(IS_ANDROID)\n  enabled = true;\n#endif\n  UpdateExtensionPref(extension_id, kPrefIncognitoEnabled,\n                      base::Value(enabled));\n  extension_pref_value_map_->SetExtensionIncognitoState(extension_id, enabled);\n}|' "$EXTENSION_PREFS"

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

# crbug.com/helium: make Android extension popup tabs APIs resolve the visible tab.
# Proxy extensions call chrome.tabs.query({active: true, lastFocusedWindow: true})
# from their popup. Android menu popups are not normal browser windows, so the
# generic current/last-focused window lookup can resolve the wrong profile/window.
# Keep the tab that opened the popup as the Android popup tab and prefer that
# window for popup-scoped tabs APIs.
if [ -f "$EXTENSION_TAB_UTIL_H" ] && [ -f "$EXTENSION_TAB_UTIL_CC" ] && [ -f "$TABS_API_CC" ]; then
    grep -q 'build/build_config.h' "$EXTENSION_TAB_UTIL_H" || \
        sed -i '/#include "base\/values.h"/a\#include "build/build_config.h"' "$EXTENSION_TAB_UTIL_H"
    grep -q 'SetAndroidExtensionPopupWebContents' "$EXTENSION_TAB_UTIL_H" || \
        sed -i '/static int GetWindowIdOfTab/a\
#if BUILDFLAG(IS_ANDROID)\
  static void SetAndroidExtensionPopupWebContents(\
      content::WebContents* web_contents);\
  static content::WebContents* GetAndroidExtensionPopupWebContents(\
      content::BrowserContext* browser_context,\
      bool include_incognito);\
#endif\
' "$EXTENSION_TAB_UTIL_H"
    grep -q 'g_android_extension_popup_tab_id' "$EXTENSION_TAB_UTIL_CC" || \
        sed -i '/bool g_disable_tab_list_editing_for_testing = false;/a\
#if BUILDFLAG(IS_ANDROID)\
int g_android_extension_popup_tab_id = -1;\
#endif\
' "$EXTENSION_TAB_UTIL_CC"
    grep -q 'g_android_extension_popup_web_contents' "$EXTENSION_TAB_UTIL_CC" || \
        sed -i '/int g_android_extension_popup_tab_id = -1;/a\
content::WebContents* g_android_extension_popup_web_contents = nullptr;' "$EXTENSION_TAB_UTIL_CC"
    grep -q 'GetAndroidExtensionPopupWebContents' "$EXTENSION_TAB_UTIL_CC" || \
        sed -i '/int ExtensionTabUtil::GetWindowIdOfTab/i\
#if BUILDFLAG(IS_ANDROID)\
void ExtensionTabUtil::SetAndroidExtensionPopupWebContents(\
    content::WebContents* web_contents) {\
  g_android_extension_popup_tab_id = web_contents ? GetTabId(web_contents) : -1;\
}\
\
content::WebContents* ExtensionTabUtil::GetAndroidExtensionPopupWebContents(\
    content::BrowserContext* browser_context,\
    bool include_incognito) {\
  if (g_android_extension_popup_tab_id < 0) {\
    return nullptr;\
  }\
  content::WebContents* web_contents = nullptr;\
  if (!GetTabById(g_android_extension_popup_tab_id, browser_context,\
                  include_incognito, &web_contents)) {\
    return nullptr;\
  }\
  return web_contents;\
}\
#endif\
' "$EXTENSION_TAB_UTIL_CC"
    perl -0pi -e 's|void ExtensionTabUtil::SetAndroidExtensionPopupWebContents\(\n    content::WebContents\* web_contents\) \{\n  g_android_extension_popup_tab_id = web_contents \? GetTabId\(web_contents\) : -1;\n\}|void ExtensionTabUtil::SetAndroidExtensionPopupWebContents(\n    content::WebContents* web_contents) {\n  g_android_extension_popup_web_contents = web_contents;\n  g_android_extension_popup_tab_id = web_contents ? GetTabId(web_contents) : -1;\n}|s' "$EXTENSION_TAB_UTIL_CC"
    perl -0pi -e 's|content::WebContents\* ExtensionTabUtil::GetAndroidExtensionPopupWebContents\(\n    content::BrowserContext\* browser_context,\n    bool include_incognito\) \{\n  if \(g_android_extension_popup_tab_id < 0\) \{\n    return nullptr;\n  \}\n  content::WebContents\* web_contents = nullptr;\n  if \(!GetTabById\(g_android_extension_popup_tab_id, browser_context,\n                  include_incognito, &web_contents\)\) \{\n    return nullptr;\n  \}\n  return web_contents;\n\}|content::WebContents* ExtensionTabUtil::GetAndroidExtensionPopupWebContents(\n    content::BrowserContext* browser_context,\n    bool include_incognito) {\n  if (g_android_extension_popup_tab_id >= 0) {\n    content::WebContents* web_contents = nullptr;\n    if (GetTabById(g_android_extension_popup_tab_id, browser_context,\n                   include_incognito, &web_contents) &&\n        web_contents) {\n      return web_contents;\n    }\n  }\n\n  if (!g_android_extension_popup_web_contents) {\n    return nullptr;\n  }\n  if (g_android_extension_popup_web_contents->GetBrowserContext() ==\n          browser_context ||\n      include_incognito) {\n    return g_android_extension_popup_web_contents;\n  }\n  return nullptr;\n}|s' "$EXTENSION_TAB_UTIL_CC"
fi
if [ -f "$MENU_DELEGATE_CC" ]; then
    grep -q 'chrome/browser/extensions/extension_tab_util.h' "$MENU_DELEGATE_CC" || \
        sed -i '/#include "chrome\/browser\/ui\/android\/extensions\/extension_action_delegate_android.h"/a\#include "chrome/browser/extensions/extension_tab_util.h"' "$MENU_DELEGATE_CC"
    perl -0pi -e 's|(void ExtensionsMenuDelegateAndroid::ExecuteAction\(\n    JNIEnv\* env,\n    const extensions::ExtensionId& extension_id,\n    content::WebContents\* web_contents\) \{\n)(?!#if BUILDFLAG\(IS_ANDROID\)\n  ExtensionTabUtil::SetAndroidExtensionPopupWebContents)|$1#if BUILDFLAG(IS_ANDROID)\n  ExtensionTabUtil::SetAndroidExtensionPopupWebContents(web_contents);\n#endif\n|s' "$MENU_DELEGATE_CC"
fi
if [ -f "$TABS_API_CC" ]; then
    python3 - "$TABS_API_CC" <<'PYCODE'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
text = text.replace(
"""#if BUILDFLAG(IS_ANDROID)
  content::WebContents* android_popup_direct_web_contents =
      ExtensionTabUtil::GetAndroidExtensionPopupWebContents(
          browser_context(), /*include_incognito=*/true);
  BrowserWindowInterface* android_popup_direct_browser =
      android_popup_direct_web_contents
          ? browser_window_util::GetBrowserForTabContents(
                *android_popup_direct_web_contents)
          : nullptr;
  const bool helium_android_popup_direct_query =
      android_popup_direct_browser && query_info_.active &&
      *query_info_.active &&
      ((query_info_.last_focused_window &&
        *query_info_.last_focused_window) ||
       (query_info_.current_window && *query_info_.current_window) ||
       window_id == extension_misc::kCurrentWindowId) &&
      !query_info_.url && index < 0 && window_type.empty();
  if (helium_android_popup_direct_query) {
    base::ListValue direct_result;
    direct_result.Append(tabs_internal::CreateTabObjectHelper(
                             android_popup_direct_web_contents, extension(),
                             source_context_type(),
                             android_popup_direct_browser, -1)
                             .ToValue());
    return RespondNow(WithArguments(std::move(direct_result)));
  }
#endif
""",
"""#if BUILDFLAG(IS_ANDROID)
  content::WebContents* android_popup_direct_web_contents =
      ExtensionTabUtil::GetAndroidExtensionPopupWebContents(
          browser_context(), /*include_incognito=*/true);
  const bool helium_android_popup_direct_query =
      android_popup_direct_web_contents && query_info_.active &&
      *query_info_.active &&
      ((query_info_.last_focused_window &&
        *query_info_.last_focused_window) ||
       (query_info_.current_window && *query_info_.current_window) ||
       window_id == extension_misc::kCurrentWindowId) &&
      !query_info_.url && index < 0 && window_type.empty();
  if (helium_android_popup_direct_query) {
    base::ListValue direct_result;
    ExtensionTabUtil::ScrubTabBehavior dont_scrub = {
        ExtensionTabUtil::kDontScrubTab, ExtensionTabUtil::kDontScrubTab};
    direct_result.Append(ExtensionTabUtil::CreateTabObject(
                             android_popup_direct_web_contents, dont_scrub,
                             extension(), nullptr, -1)
                             .ToValue());
    return RespondNow(WithArguments(std::move(direct_result)));
  }
#endif
""",
)
text = text.replace(
"""#if BUILDFLAG(IS_ANDROID)
  content::WebContents* android_popup_direct_web_contents =
      ExtensionTabUtil::GetAndroidExtensionPopupWebContents(
          browser_context(), /*include_incognito=*/true);
  const bool helium_android_popup_direct_query =
      android_popup_direct_web_contents && query_info_.active &&
      *query_info_.active &&
      ((query_info_.last_focused_window &&
        *query_info_.last_focused_window) ||
       (query_info_.current_window && *query_info_.current_window) ||
       window_id == extension_misc::kCurrentWindowId) &&
      !query_info_.url && index < 0 && window_type.empty();
  if (helium_android_popup_direct_query) {
    base::ListValue direct_result;
    direct_result.Append(tabs_internal::CreateTabObjectHelper(
                             android_popup_direct_web_contents, extension(),
                             source_context_type(), nullptr, -1)
                             .ToValue());
    return RespondNow(WithArguments(std::move(direct_result)));
  }
#endif
""",
"""#if BUILDFLAG(IS_ANDROID)
  content::WebContents* android_popup_direct_web_contents =
      ExtensionTabUtil::GetAndroidExtensionPopupWebContents(
          browser_context(), /*include_incognito=*/true);
  const bool helium_android_popup_direct_query =
      android_popup_direct_web_contents && query_info_.active &&
      *query_info_.active &&
      ((query_info_.last_focused_window &&
        *query_info_.last_focused_window) ||
       (query_info_.current_window && *query_info_.current_window) ||
       window_id == extension_misc::kCurrentWindowId) &&
      !query_info_.url && index < 0 && window_type.empty();
  if (helium_android_popup_direct_query) {
    base::ListValue direct_result;
    ExtensionTabUtil::ScrubTabBehavior dont_scrub = {
        ExtensionTabUtil::kDontScrubTab, ExtensionTabUtil::kDontScrubTab};
    direct_result.Append(ExtensionTabUtil::CreateTabObject(
                             android_popup_direct_web_contents, dont_scrub,
                             extension(), nullptr, -1)
                             .ToValue());
    return RespondNow(WithArguments(std::move(direct_result)));
  }
#endif
""",
)
text = text.replace(
    "ExtensionTabUtil::GetAndroidExtensionPopupWebContents(\n"
    "        function->browser_context(), function->include_incognito_information());",
    "ExtensionTabUtil::GetAndroidExtensionPopupWebContents(\n"
    "        function->browser_context(), /*include_incognito=*/true);",
)
text = text.replace(
    "ExtensionTabUtil::GetAndroidExtensionPopupWebContents(\n"
    "      browser_context(), include_incognito_information());",
    "ExtensionTabUtil::GetAndroidExtensionPopupWebContents(\n"
    "      browser_context(), /*include_incognito=*/true);",
)
text = text.replace(
    "ExtensionTabUtil::GetAndroidExtensionPopupWebContents(\n"
    "          browser_context(), include_incognito_information());",
    "ExtensionTabUtil::GetAndroidExtensionPopupWebContents(\n"
    "          browser_context(), /*include_incognito=*/true);",
)

def replace_once(old, new, marker):
    global text
    if marker in text:
        return
    if old not in text:
        raise SystemExit(f"pattern not found while patching {path}: {marker}")
    text = text.replace(old, new, 1)

replace_once(
"""  if (tab_id != -1) {
    // We assume this call leaves web_contents unchanged if it is unsuccessful.
    tabs_internal::GetTabById(tab_id, function->browser_context(),
                              function->include_incognito_information(),
                              /*window_out=*/nullptr, &web_contents,
                              /*index_out=*/nullptr, error);
  } else {
""",
"""  if (tab_id != -1) {
    // We assume this call leaves web_contents unchanged if it is unsuccessful.
    tabs_internal::GetTabById(tab_id, function->browser_context(),
                              function->include_incognito_information(),
                              /*window_out=*/nullptr, &web_contents,
                              /*index_out=*/nullptr, error);
  } else {
#if BUILDFLAG(IS_ANDROID)
    web_contents = ExtensionTabUtil::GetAndroidExtensionPopupWebContents(
        function->browser_context(), /*include_incognito=*/true);
    if (web_contents) {
      return web_contents;
    }
#endif
""",
    "function->browser_context(), /*include_incognito=*/true)",
)
replace_once(
"""  if (caller_contents && ExtensionTabUtil::GetTabId(caller_contents) >= 0) {
    return RespondNow(ArgumentList(
        tabs::Get::Results::Create(tabs_internal::CreateTabObjectHelper(
            caller_contents, extension(), source_context_type(), nullptr,
            -1))));
  }
""",
"""  if (caller_contents && ExtensionTabUtil::GetTabId(caller_contents) >= 0) {
    return RespondNow(ArgumentList(
        tabs::Get::Results::Create(tabs_internal::CreateTabObjectHelper(
            caller_contents, extension(), source_context_type(), nullptr,
            -1))));
  }
#if BUILDFLAG(IS_ANDROID)
  caller_contents = ExtensionTabUtil::GetAndroidExtensionPopupWebContents(
      browser_context(), /*include_incognito=*/true);
  if (caller_contents && ExtensionTabUtil::GetTabId(caller_contents) >= 0) {
    return RespondNow(ArgumentList(
        tabs::Get::Results::Create(tabs_internal::CreateTabObjectHelper(
            caller_contents, extension(), source_context_type(), nullptr,
            -1))));
  }
#endif
""",
    "caller_contents = ExtensionTabUtil::GetAndroidExtensionPopupWebContents",
)
replace_once(
"""  if (current_window_controller) {
    current_browser = current_window_controller->GetBrowserWindowInterface();
    // Note: current_browser may still be null.
  }
""",
"""  if (current_window_controller) {
    current_browser = current_window_controller->GetBrowserWindowInterface();
    // Note: current_browser may still be null.
  }
#if BUILDFLAG(IS_ANDROID)
  content::WebContents* android_popup_web_contents =
      ExtensionTabUtil::GetAndroidExtensionPopupWebContents(
          browser_context(), /*include_incognito=*/true);
  BrowserWindowInterface* android_popup_browser =
      android_popup_web_contents
          ? browser_window_util::GetBrowserForTabContents(
                *android_popup_web_contents)
          : nullptr;
  if (android_popup_browser &&
      (window_id == extension_misc::kCurrentWindowId ||
       (query_info_.current_window && *query_info_.current_window) ||
       (query_info_.last_focused_window &&
        *query_info_.last_focused_window))) {
    current_browser = android_popup_browser;
    last_active_browser = android_popup_browser;
  }
#endif
""",
    "android_popup_web_contents",
)
replace_once(
"""  Profile* profile = Profile::FromBrowserContext(browser_context());
""",
"""#if BUILDFLAG(IS_ANDROID)
  content::WebContents* android_popup_direct_web_contents =
      ExtensionTabUtil::GetAndroidExtensionPopupWebContents(
          browser_context(), /*include_incognito=*/true);
  const bool helium_android_popup_direct_query =
      android_popup_direct_web_contents && query_info_.active &&
      *query_info_.active &&
      ((query_info_.last_focused_window &&
        *query_info_.last_focused_window) ||
       (query_info_.current_window && *query_info_.current_window) ||
       window_id == extension_misc::kCurrentWindowId) &&
      !query_info_.url && index < 0 && window_type.empty();
  if (helium_android_popup_direct_query) {
    base::ListValue direct_result;
    ExtensionTabUtil::ScrubTabBehavior dont_scrub = {
        ExtensionTabUtil::kDontScrubTab, ExtensionTabUtil::kDontScrubTab};
    direct_result.Append(ExtensionTabUtil::CreateTabObject(
                             android_popup_direct_web_contents, dont_scrub,
                             extension(), nullptr, -1)
                             .ToValue());
    return RespondNow(WithArguments(std::move(direct_result)));
  }
#endif

  Profile* profile = Profile::FromBrowserContext(browser_context());
""",
    "helium_android_popup_direct_query",
)
replace_once(
"""  if (!include_incognito_information() && profile != candidate_profile) {
    return false;
  }
""",
"""#if BUILDFLAG(IS_ANDROID)
  if (!include_incognito_information() && profile != candidate_profile &&
      candidate_browser != current_browser &&
      candidate_browser != last_active_browser) {
    return false;
  }
#else
  if (!include_incognito_information() && profile != candidate_profile) {
    return false;
  }
#endif
""",
    "candidate_browser != current_browser",
)
path.write_text(text)
PYCODE
fi
