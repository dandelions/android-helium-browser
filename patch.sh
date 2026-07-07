#!/bin/bash

mkdir -p chrome/android/java/res_helium_base
for icon in $(find chrome/android/java/res_helium_base -type f -name '*.png'); do convert $icon -fill navy -tint 36 $icon; done
# sed -i 's|Google LLC|jqssun, Google LLC|' chrome/browser/ui/android/strings/android_chrome_strings.grd

sed -i '/feature_overrides.EnableFeature(::features::kSkipVulkanBlocklist);/d' chrome/browser/chrome_browser_field_trials.cc
sed -i '/feature_overrides.EnableFeature(::features::kDefaultANGLEVulkan);/d' chrome/browser/chrome_browser_field_trials.cc
sed -i '/feature_overrides.EnableFeature(::features::kVulkanFromANGLE);/d' chrome/browser/chrome_browser_field_trials.cc
sed -i '/feature_overrides.EnableFeature(::features::kDefaultPassthroughCommandDecoder);/d' chrome/browser/chrome_browser_field_trials.cc

# dev
sed -i 's/BASE_FEATURE(kSubmenusInAppMenu, base::FEATURE_DISABLED_BY_DEFAULT);/BASE_FEATURE(kSubmenusInAppMenu, base::FEATURE_ENABLED_BY_DEFAULT);/' chrome/browser/flags/android/chrome_feature_list.cc
sed -i '/BASE_FEATURE(kTaskManagerClank,/,/);/ s/base::FEATURE_DISABLED_BY_DEFAULT/base::FEATURE_ENABLED_BY_DEFAULT/' chrome/browser/task_manager/common/task_manager_features.cc
sed -i 's/BASE_FEATURE(kAndroidDevToolsFrontend, base::FEATURE_DISABLED_BY_DEFAULT);/BASE_FEATURE(kAndroidDevToolsFrontend, base::FEATURE_ENABLED_BY_DEFAULT);/' content/public/common/content_features.cc
sed -i 's|if (!DeviceFormFactor.isNonMultiDisplayContextOnTablet(mContext)) {|if (false) {|' chrome/android/java/src/org/chromium/chrome/browser/tabbed_mode/TabbedAppMenuPropertiesDelegate.java
sed -i 's|boolean shouldShowDeveloperMenu() {|boolean shouldShowDeveloperMenu() { if (true) return DevToolsWindowAndroid.isDevToolsAllowedFor(getProfile(), mItemDelegate.getWebContents());|' chrome/android/java/src/org/chromium/chrome/browser/contextmenu/ChromeContextMenuPopulator.java
sed -i 's|TabUtils.isUsingDesktopUserAgent(mItemDelegate.getWebContents())|(true \|\| TabUtils.isUsingDesktopUserAgent(mItemDelegate.getWebContents()))|' chrome/android/java/src/org/chromium/chrome/browser/contextmenu/ChromeContextMenuPopulator.java
perl -0pi -e 's|(<activity\n            android:name="org\.chromium\.chrome\.browser\.devtools\.DevToolsActivity"\n            android:theme="\@style/Theme\.Chromium\.Activity"\n            android:exported="false"\n)(?!            android:resizeableActivity="true"\n)|$1            android:resizeableActivity="true"\n|' chrome/android/java/AndroidManifest.xml
perl -0pi -e 's|(<activity\n            android:name="org\.chromium\.chrome\.browser\.devtools\.DevToolsActivity"(?:(?!</activity>).)*?            android:resizeableActivity="true"\n)(?!            android:supportsPictureInPicture="true"\n)|$1            android:supportsPictureInPicture="true"\n|s' chrome/android/java/AndroidManifest.xml
perl -0pi -e 's|(<activity\n            android:name="org\.chromium\.chrome\.browser\.devtools\.DevToolsActivity"(?:(?!</activity>).)*?            \{\{ self\.extra_web_rendering_activity_definitions\(\) \}\}\n)(?!            <property android:name="android\.window\.PROPERTY_SUPPORTS_MULTI_INSTANCE_SYSTEM_UI")|$1            <property android:name="android.window.PROPERTY_SUPPORTS_MULTI_INSTANCE_SYSTEM_UI"\n                android:value="true" />\n|s' chrome/android/java/AndroidManifest.xml
grep -q 'org.chromium.chrome.browser.flags.ActivityType' chrome/android/java/src/org/chromium/chrome/browser/customtabs/features/minimizedcustomtab/CustomTabMinimizationManager.java || sed -i '/import org.chromium.chrome.browser.customtabs.CustomTabsConnection;/a\import org.chromium.chrome.browser.flags.ActivityType;' chrome/android/java/src/org/chromium/chrome/browser/customtabs/features/minimizedcustomtab/CustomTabMinimizationManager.java
grep -q 'mIntentData.getActivityType() == ActivityType.DEV_TOOLS' chrome/android/java/src/org/chromium/chrome/browser/customtabs/features/minimizedcustomtab/CustomTabMinimizationManager.java || sed -i '/if (!(mTabProvider.get() != null)) return;/a\
        if (mIntentData.getActivityType() == ActivityType.DEV_TOOLS) {\
            mActivity.moveTaskToBack(true);\
            return;\
        }' chrome/android/java/src/org/chromium/chrome/browser/customtabs/features/minimizedcustomtab/CustomTabMinimizationManager.java
grep -q 'org.chromium.chrome.browser.flags.ActivityType' chrome/android/java/src/org/chromium/chrome/browser/customtabs/features/minimizedcustomtab/MinimizedFeatureUtils.java || sed -i '/import org.chromium.chrome.browser.flags.ChromeFeatureList;/a\import org.chromium.chrome.browser.flags.ActivityType;' chrome/android/java/src/org/chromium/chrome/browser/customtabs/features/minimizedcustomtab/MinimizedFeatureUtils.java
grep -q 'intentDataProvider.getActivityType() == ActivityType.DEV_TOOLS' chrome/android/java/src/org/chromium/chrome/browser/customtabs/features/minimizedcustomtab/MinimizedFeatureUtils.java || sed -i '/public static boolean shouldEnableMinimizedCustomTabs(/,/if (intentDataProvider.hasTargetNetwork()) return false;/ s|if (intentDataProvider.hasTargetNetwork()) return false;|if (intentDataProvider.getActivityType() == ActivityType.DEV_TOOLS) return false;\n        if (intentDataProvider.hasTargetNetwork()) return false;|' chrome/android/java/src/org/chromium/chrome/browser/customtabs/features/minimizedcustomtab/MinimizedFeatureUtils.java
sed -i '/public @TitleVisibility int getTitleVisibilityState()/,/^    }/ s|return TitleVisibility.VISIBLE;|return TitleVisibility.HIDDEN;|' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsIntentDataProvider.java
sed -i '/public boolean isCloseButtonEnabled()/,/^    }/ s|return false;|return true;|' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsIntentDataProvider.java
sed -i 's#connection.shouldEnableOmniboxForIntent(mIntentDataProvider.get());#connection.shouldEnableOmniboxForIntent(mIntentDataProvider.get())\n                        || mIntentDataProvider.get().getActivityType() == ActivityType.DEV_TOOLS;#' chrome/android/java/src/org/chromium/chrome/browser/customtabs/BaseCustomTabRootUiCoordinator.java
grep -q 'org.chromium.cc.input.BrowserControlsState' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java || sed -i '/import org.chromium.base.ContextUtils;/a\import org.chromium.cc.input.BrowserControlsState;' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java
grep -q 'android.view.Gravity' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java || sed -i '/import android.content.Intent;/a\import android.view.Gravity;' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java
grep -q 'android.view.ViewGroup' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java || sed -i '/import android.view.Gravity;/a\import android.view.ViewGroup;' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java
grep -q 'android.widget.Button' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java || sed -i '/import android.view.ViewGroup;/a\import android.widget.Button;' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java
grep -q 'android.widget.FrameLayout' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java || sed -i '/import android.widget.Button;/a\import android.widget.FrameLayout;' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java
grep -q 'addInspectedPageSwitcher(WebContents devToolsWebContents)' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java || perl -0pi -e 's~(\n    \@Override\n    public void finishNativeInitialization\(\) \{)~\n    private void addInspectedPageSwitcher(WebContents devToolsWebContents) {\n        Button switchButton = new Button(this);\n        switchButton.setText("Page");\n        switchButton.setAllCaps(false);\n        switchButton.setOnClickListener(\n                v -> DevToolsWindowAndroid.activateInspectedPage(devToolsWebContents));\n        FrameLayout.LayoutParams params =\n                new FrameLayout.LayoutParams(\n                        ViewGroup.LayoutParams.WRAP_CONTENT,\n                        ViewGroup.LayoutParams.WRAP_CONTENT,\n                        Gravity.TOP | Gravity.END);\n        int margin = (int) (8 * getResources().getDisplayMetrics().density);\n        params.setMargins(margin, margin, margin, margin);\n        addContentView(switchButton, params);\n    }\n$1~' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java
grep -q 'addInspectedPageSwitcher(webContents)' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java || perl -0pi -e 's~(DevToolsWindowAndroid\.attachToBrowser\(\n                    webContents, task\.getOrCreateNativeBrowserWindowPtr\(profile\)\);\n)~$1            addInspectedPageSwitcher(webContents);\n~' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java
grep -q 'setBrowserControlsState(BrowserControlsState.SHOWN)' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java || sed -i '/super.finishNativeInitialization();/a\        getCustomTabToolbarCoordinator().setBrowserControlsState(BrowserControlsState.SHOWN);' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java
grep -q 'public static void activateInspectedPage' chrome/browser/devtools/android/java/src/org/chromium/chrome/browser/devtools/DevToolsWindowAndroid.java || perl -0pi -e 's~(\n    /\*\*\n     \* Attaches the DevTools frontend web contents to the browser window\.)~\n    public static void activateInspectedPage(WebContents webContents) {\n        DevToolsWindowAndroidJni.get().activateInspectedPage(webContents);\n    }\n$1~' chrome/browser/devtools/android/java/src/org/chromium/chrome/browser/devtools/DevToolsWindowAndroid.java
grep -q '^        void activateInspectedPage(WebContents webContents);' chrome/browser/devtools/android/java/src/org/chromium/chrome/browser/devtools/DevToolsWindowAndroid.java || sed -i '/void attachToBrowser(WebContents webContents, long nativeBrowserWindowPtr);/i\        void activateInspectedPage(WebContents webContents);\n' chrome/browser/devtools/android/java/src/org/chromium/chrome/browser/devtools/DevToolsWindowAndroid.java
grep -q 'web_contents_delegate.h' chrome/browser/devtools/android/devtools_window_android.cc || sed -i '/#include "content\/public\/browser\/web_contents.h"/a\#include "content/public/browser/web_contents_delegate.h"' chrome/browser/devtools/android/devtools_window_android.cc
grep -q 'JNI_DevToolsWindowAndroid_ActivateInspectedPage' chrome/browser/devtools/android/devtools_window_android.cc || perl -0pi -e 's~(\nstatic void JNI_DevToolsWindowAndroid_AttachToBrowser\()~\nstatic void JNI_DevToolsWindowAndroid_ActivateInspectedPage(\n    JNIEnv* env,\n    const jni_zero::JavaRef<jobject>& java_web_contents) {\n#if BUILDFLAG(ENABLE_DEVTOOLS_FRONTEND)\n  content::WebContents* web_contents =\n      content::WebContents::FromJavaWebContents(java_web_contents);\n  DevToolsWindow* window = DevToolsWindow::AsDevToolsWindow(web_contents);\n  if (!window) {\n    return;\n  }\n  content::WebContents* inspected_web_contents =\n      window->GetInspectedWebContents();\n  if (!inspected_web_contents || !inspected_web_contents->GetDelegate()) {\n    return;\n  }\n  inspected_web_contents->GetDelegate()->ActivateContents(\n      inspected_web_contents);\n  inspected_web_contents->Focus();\n#endif\n}\n$1~' chrome/browser/devtools/android/devtools_window_android.cc
grep -q 'components/tabs/public/tab_interface.h' chrome/browser/devtools/devtools_window.cc || sed -i '/#include "components\/strings\/grit\/components_strings.h"/a\#include "components/tabs/public/tab_interface.h"' chrome/browser/devtools/devtools_window.cc
grep -q 'HeliumAndroidDevToolsSameWindow' chrome/browser/devtools/devtools_window.cc || perl -0pi -e 's~#if BUILDFLAG\(IS_ANDROID\)\n  if \(!owned_main_web_contents_ \|\| launched_activity_\) \{\n    return;\n  \}\n  JNIEnv\* env = base::android::AttachCurrentThread\(\);\n  Java_DevToolsActivity_launchDevToolsActivity\(\n      env, main_web_contents_->GetJavaWebContents\(\)\);\n\n  launched_activity_ = true;\n\n  OverrideAndSyncDevToolsRendererPrefs\(\);~#if BUILDFLAG(IS_ANDROID)\n  if (!owned_main_web_contents_ || launched_activity_) {\n    return;\n  }\n  content::WebContents* inspected_web_contents = GetInspectedWebContents();\n  tabs::TabInterface* inspected_tab =\n      inspected_web_contents\n          ? tabs::TabInterface::MaybeGetFromContents(inspected_web_contents)\n          : nullptr;\n  BrowserWindowInterface* inspected_browser =\n      inspected_tab ? inspected_tab->GetBrowserWindowInterface() : nullptr;\n  TabListInterface* inspected_tab_list =\n      inspected_browser ? TabListInterface::From(inspected_browser) : nullptr;\n  if (inspected_tab_list) {\n    // HeliumAndroidDevToolsSameWindow: put DevTools in the inspected page window.\n    AttachToBrowser(inspected_browser);\n  } else {\n    JNIEnv* env = base::android::AttachCurrentThread();\n    Java_DevToolsActivity_launchDevToolsActivity(\n        env, main_web_contents_->GetJavaWebContents());\n  }\n\n  launched_activity_ = true;\n\n  OverrideAndSyncDevToolsRendererPrefs();~' chrome/browser/devtools/devtools_window.cc
perl -0pi -e 's~(#if BUILDFLAG\(IS_ANDROID\)\n)    NOTIMPLEMENTED\(\);\n(#else\n    if \(browser_\) \{)~$1    WebContents* inspected_tab = GetInspectedWebContents();\n    if (inspected_tab && inspected_tab->GetDelegate()) {\n      inspected_tab->GetDelegate()->ActivateContents(inspected_tab);\n      inspected_tab->Focus();\n    }\n$2~' chrome/browser/devtools/devtools_window.cc
perl -0pi -e 's~(#if BUILDFLAG\(IS_ANDROID\)\n)  NOTIMPLEMENTED\(\);\n(#else\n  if \(is_docked_ && GetInspectedBrowserWindow\(\)\) \{)~$1  tabs::TabInterface* devtools_tab =\n      tabs::TabInterface::MaybeGetFromContents(main_web_contents_);\n  BrowserWindowInterface* devtools_browser =\n      devtools_tab ? devtools_tab->GetBrowserWindowInterface() : nullptr;\n  TabListInterface* tab_list =\n      devtools_browser ? TabListInterface::From(devtools_browser) : nullptr;\n  if (tab_list && devtools_tab) {\n    tab_list->ActivateTab(devtools_tab->GetHandle());\n    main_web_contents_->Focus();\n  }\n$2~' chrome/browser/devtools/devtools_window.cc
grep -q 'InspectElementCompleted.AndroidActivateWindow' chrome/browser/devtools/devtools_window.cc || perl -0pi -e 's~void DevToolsWindow::InspectElementCompleted\(\) \{\n  if \(!inspect_element_start_time_\.is_null\(\)\) \{\n    UMA_HISTOGRAM_TIMES\("DevTools\.InspectElement",\n                        base::TimeTicks::Now\(\) - inspect_element_start_time_\);\n    inspect_element_start_time_ = base::TimeTicks\(\);\n  \}\n\}~void DevToolsWindow::InspectElementCompleted() {\n  if (!inspect_element_start_time_.is_null()) {\n    UMA_HISTOGRAM_TIMES("DevTools.InspectElement",\n                        base::TimeTicks::Now() - inspect_element_start_time_);\n    inspect_element_start_time_ = base::TimeTicks();\n  }\n#if BUILDFLAG(IS_ANDROID)\n  // InspectElementCompleted.AndroidActivateWindow: return to DevTools after picking an element.\n  ActivateWindow();\n#endif\n}~' chrome/browser/devtools/devtools_window.cc
grep -q 'tab_list->ActivateTab(tab->GetHandle())' chrome/browser/devtools/devtools_window.cc || perl -0pi -e 's~  auto\* tab_list = TabListInterface::From\(browser\);\n  if \(!tab_list\) \{\n    return;\n  \}\n  tab_list->InsertWebContentsAt\(0, std::move\(owned_web_contents\), false,\n                                std::nullopt\);~  auto* tab_list = TabListInterface::From(browser);\n  if (!tab_list) {\n    return;\n  }\n  browser_ = browser;\n  tabs::TabInterface* tab = tab_list->InsertWebContentsAt(\n      0, std::move(owned_web_contents), false, std::nullopt);\n  if (tab) {\n    tab_list->ActivateTab(tab->GetHandle());\n  }~' chrome/browser/devtools/devtools_window.cc

# ext: app menu
sed -i 's|return ExtensionUi.isEnabled(getProfileFromTabModel());|return true;|' chrome/android/java/src/org/chromium/chrome/browser/tabbed_mode/TabbedAppMenuPropertiesDelegate.java
sed -i '/coordinator.showExtensionsMenu();/c\            if (coordinator != null) {\
                coordinator.showExtensionsMenu();\
            } else {\
                LoadUrlParams params = new LoadUrlParams(UrlConstants.CHROME_EXTENSIONS_URL, PageTransition.AUTO_TOPLEVEL);\
                if (currentTab == null) {\
                    getTabCreator(getCurrentTabModel().isIncognito()).createNewTab(params, TabLaunchType.FROM_CHROME_UI, /* parent= */ null);\
                } else {\
                    currentTab.loadUrl(params);\
                }\
            }' chrome/android/java/src/org/chromium/chrome/browser/ChromeTabbedActivity.java
grep -q 'org.chromium.chrome.browser.ui.toolbar.InvocationSource' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java || sed -i '/import org.chromium.chrome.browser.ui.extensions.ExtensionsToolbarBridge;/a\import org.chromium.chrome.browser.ui.toolbar.InvocationSource;' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
grep -q 'ExtensionsToolbarBridge mToolbarBridge;' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java || sed -i '/private final ExtensionsMenuBridge mMenuBridge;/a\    private ExtensionsToolbarBridge mToolbarBridge;' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
sed -i 's|private final ExtensionsToolbarBridge mToolbarBridge;|private ExtensionsToolbarBridge mToolbarBridge;|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
grep -q 'mToolbarBridge = toolbarBridge;' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java || perl -0pi -e 's|(\n[ \t]*)(mMenuBridge[ \t]*=)|$1mToolbarBridge = toolbarBridge;\n$1$2|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
sed -i 's|(view) -> openExtensionFromMenu(entry.id))|(view) -> mMenuBridge.executeAction(entry.id))|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
sed -i 's|(view) -> openUrlFromMenu(UrlConstants.CHROME_EXTENSIONS_ID_URL + entry.id))|(view) -> mMenuBridge.executeAction(entry.id))|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
sed -i 's|(view) -> mToolbarBridge.executeUserAction(entry.id, InvocationSource.TOOLBAR_BUTTON))|(view) -> mMenuBridge.executeAction(entry.id))|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
sed -i 's|(view) -> openExtensionOptionsFromMenu(entry.id))|(view) -> mMenuBridge.executeAction(entry.id))|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
perl -0pi -e 's|if \(hasPoppedOutAction\(\) && itemWidth <= availableWidth\) \{\n            mCanShowPoppedOutAction = true;\n            return itemWidth;\n        \} else \{\n            mCanShowPoppedOutAction = false;\n            return 0;\n        \}|if (hasPoppedOutAction()) {\n            mCanShowPoppedOutAction = true;\n            return itemWidth;\n        } else {\n            mCanShowPoppedOutAction = false;\n            return 0;\n        }|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionActionListMediator.java
perl -0pi -e 's|if \(findIndexForId\(actionId\) == -1\) \{\n            mPoppedOutActionId = actionId;\n        \}|if (findIndexForId(actionId) == -1) {\n            mPoppedOutActionId = actionId;\n            mCanShowPoppedOutAction = true;\n            reconcileActionItems();\n        }|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionActionListMediator.java
grep -q 'private void openExtensionOptionsFromMenu' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java || sed -i '/private void openUrlFromMenu(String url) {/i\
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
' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
grep -q 'getOptionsPageUrl(String extensionId)' chrome/browser/ui/android/extensions/java/src/org/chromium/chrome/browser/ui/extensions/ExtensionsMenuBridge.java || sed -i '/public void executeAction(String extensionId) {/i\
    public String getOptionsPageUrl(String extensionId) {\
        return ExtensionsMenuBridgeJni.get()\
                .getOptionsPageUrl(mNativeExtensionsMenuDelegateAndroid, extensionId);\
    }\
' chrome/browser/ui/android/extensions/java/src/org/chromium/chrome/browser/ui/extensions/ExtensionsMenuBridge.java
grep -q '^        String getOptionsPageUrl(' chrome/browser/ui/android/extensions/java/src/org/chromium/chrome/browser/ui/extensions/ExtensionsMenuBridge.java || perl -0pi -e 's|(\n\s*\@NativeMethods\n\s*public interface Natives \{\n)|$1        \@JniType("std::string")\n        String getOptionsPageUrl(\n                long nativeExtensionsMenuDelegateAndroid,\n                \@JniType("std::string") String extensionId);\n\n|' chrome/browser/ui/android/extensions/java/src/org/chromium/chrome/browser/ui/extensions/ExtensionsMenuBridge.java
grep -q '#include <string>' chrome/browser/ui/android/extensions/extensions_menu_delegate_android.h || sed -i '/^#include "base\/android\/jni_android.h"/i\#include <string>' chrome/browser/ui/android/extensions/extensions_menu_delegate_android.h
grep -q 'GetOptionsPageUrl(JNIEnv' chrome/browser/ui/android/extensions/extensions_menu_delegate_android.h || sed -i '/void ExecuteAction(JNIEnv\* env, const extensions::ExtensionId& extension_id);/a\  std::string GetOptionsPageUrl(JNIEnv* env, const std::string& extension_id);' chrome/browser/ui/android/extensions/extensions_menu_delegate_android.h
grep -q 'extensions/common/manifest_handlers/options_page_info.h' chrome/browser/ui/android/extensions/extensions_menu_delegate_android.cc || sed -i '/#include "chrome\/browser\/ui\/android\/extensions\/extension_action_delegate_android.h"/a\#include "chrome/browser/profiles/profile.h"\n#include "extensions/browser/extension_registry.h"\n#include "extensions/common/manifest_handlers/options_page_info.h"' chrome/browser/ui/android/extensions/extensions_menu_delegate_android.cc
grep -q 'ExtensionsMenuDelegateAndroid::GetOptionsPageUrl' chrome/browser/ui/android/extensions/extensions_menu_delegate_android.cc || sed -i '/void ExtensionsMenuDelegateAndroid::ExecuteAction(/i\
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
' chrome/browser/ui/android/extensions/extensions_menu_delegate_android.cc
sed -i '/#include "chrome\/browser\/extensions\/extension_view_host_factory.h"/a\#include "build/build_config.h"\n#include "chrome/browser/extensions/extension_tab_util.h"\n#include "chrome/browser/profiles/profile.h"\n#include "chrome/browser/tab_list/tab_list_interface.h"\n#include "chrome/browser/ui/browser_window/public/browser_window_interface.h"\n#include "components/tabs/public/tab_interface.h"\n#include "extensions/browser/extension_registry.h"' chrome/browser/ui/android/extensions/extension_action_delegate_android.cc
perl -0pi -e 's|void ExtensionActionDelegateAndroid::ShowContextMenuAsFallback\(\) \{\n  const extensions::Extension\* extension =\n      extensions::ExtensionRegistry::Get\(browser_->GetProfile\(\)\)\n          ->enabled_extensions\(\)\n          \.GetByID\(action_id_\);\n  if \(extension &&\n      extensions::ExtensionTabUtil::OpenOptionsPage\(extension, browser_\)\) \{\n    return;\n  \}\n\n  toolbar_android_->ShowContextMenu\(action_id_\);\n\}|void ExtensionActionDelegateAndroid::ShowContextMenuAsFallback() {\n  toolbar_android_->ShowContextMenu(action_id_);\n}|' chrome/browser/ui/android/extensions/extension_action_delegate_android.cc

# Menu action popups should be anchored to the clicked menu row, not by
# temporarily popping the extension action into the toolbar.
BRIDGE=chrome/browser/ui/android/extensions/java/src/org/chromium/chrome/browser/ui/extensions/ExtensionsMenuBridge.java
MENU_MEDIATOR=chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
MENU_COORDINATOR=chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuCoordinator.java
TOOLBAR=chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
MENU_DELEGATE_CC=chrome/browser/ui/android/extensions/extensions_menu_delegate_android.cc
MENU_DELEGATE_H=chrome/browser/ui/android/extensions/extensions_menu_delegate_android.h
ACTION_DELEGATE_CC=chrome/browser/ui/android/extensions/extension_action_delegate_android.cc
ACTION_DELEGATE_H=chrome/browser/ui/android/extensions/extension_action_delegate_android.h
ACTION_LIST_MEDIATOR=chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionActionListMediator.java
TABS_API_CC=chrome/browser/extensions/api/tabs/tabs_api.cc
EXTENSION_TAB_UTIL_CC=chrome/browser/extensions/extension_tab_util.cc
EXTENSION_TAB_UTIL_H=chrome/browser/extensions/extension_tab_util.h
perl -0pi -e 's|if \(hasPoppedOutAction\(\)\) \{\n            mCanShowPoppedOutAction = true;\n            return itemWidth;\n        \} else \{\n            mCanShowPoppedOutAction = false;\n            return 0;\n        \}|if (hasPoppedOutAction() && itemWidth <= availableWidth) {\n            mCanShowPoppedOutAction = true;\n            return itemWidth;\n        } else {\n            mCanShowPoppedOutAction = false;\n            return 0;\n        }|' "$ACTION_LIST_MEDIATOR"
perl -0pi -e 's|if \(findIndexForId\(actionId\) == -1\) \{\n            mPoppedOutActionId = actionId;\n            mCanShowPoppedOutAction = true;\n            reconcileActionItems\(\);\n        \}|if (findIndexForId(actionId) == -1) {\n            mPoppedOutActionId = actionId;\n        }|' "$ACTION_LIST_MEDIATOR"
grep -q 'org.chromium.chrome.browser.tabmodel.TabModelSelector' "$MENU_COORDINATOR" || sed -i '/import org.chromium.chrome.browser.tabmodel.TabCreator;/a\import org.chromium.chrome.browser.tabmodel.TabModelSelector;' "$MENU_COORDINATOR"
grep -q 'org.chromium.components.embedder_support.contextmenu.ContextMenuPopulatorFactory' "$MENU_COORDINATOR" || sed -i '/import org.chromium.chrome.browser.user_education.UserEducationHelper;/a\import org.chromium.components.embedder_support.contextmenu.ContextMenuPopulatorFactory;' "$MENU_COORDINATOR"
grep -q 'org.chromium.content_public.browser.selection.SelectionDropdownMenuDelegate' "$MENU_COORDINATOR" || sed -i '/import org.chromium.content_public.browser.WebContents;/a\import org.chromium.content_public.browser.selection.SelectionDropdownMenuDelegate;' "$MENU_COORDINATOR"
grep -q 'org.chromium.ui.base.WindowAndroid' "$MENU_COORDINATOR" || sed -i '/import org.chromium.content_public.browser.selection.SelectionDropdownMenuDelegate;/a\import org.chromium.ui.base.WindowAndroid;' "$MENU_COORDINATOR"
grep -q 'private final WindowAndroid mWindowAndroid;' "$MENU_COORDINATOR" || sed -i '/private final TabCreator mTabCreator;/a\    private final WindowAndroid mWindowAndroid;' "$MENU_COORDINATOR"
grep -q 'mContextMenuPopulatorFactory' "$MENU_COORDINATOR" || sed -i '/private final TabCreator mTabCreator;/a\    private final @Nullable ContextMenuPopulatorFactory mContextMenuPopulatorFactory;\n    private final @Nullable SelectionDropdownMenuDelegate mSelectionDropdownMenuDelegate;\n    private final TabModelSelector mTabModelSelector;' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n            WindowAndroid windowAndroid,){2,}|\n            WindowAndroid windowAndroid,|g' "$MENU_COORDINATOR"
grep -q 'WindowAndroid windowAndroid,' "$MENU_COORDINATOR" || perl -0pi -e 's|(\n            ExtensionsToolbarBridge extensionsToolbarBridge,)|$1\n            WindowAndroid windowAndroid,|' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,){2,}|\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,|g' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n            ExtensionsToolbarBridge extensionsToolbarBridge,\n)            WindowAndroid windowAndroid,\n(\s*\@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,)|$1$2|g' "$MENU_COORDINATOR"
grep -q 'ContextMenuPopulatorFactory contextMenuPopulatorFactory,' "$MENU_COORDINATOR" || perl -0pi -e 's|(\n            ExtensionsToolbarBridge extensionsToolbarBridge,)|$1\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,|' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;){2,}|\n        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;|g' "$MENU_COORDINATOR"
grep -q 'mContextMenuPopulatorFactory = contextMenuPopulatorFactory;' "$MENU_COORDINATOR" || perl -0pi -e 's|(\n        mTabCreator = tabCreator;\n        mTask = task;\n        mProfile = profile;\n)|        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;\n$1|' "$MENU_COORDINATOR"
grep -q 'mContextMenuPopulatorFactory = contextMenuPopulatorFactory;' "$MENU_COORDINATOR" || sed -i '/mExtensionsToolbarBridge = extensionsToolbarBridge;/a\        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;' "$MENU_COORDINATOR"
grep -q 'mWindowAndroid = windowAndroid;' "$MENU_COORDINATOR" || sed -i '/mExtensionsToolbarBridge = extensionsToolbarBridge;/a\        mWindowAndroid = windowAndroid;' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n                        mContextMenuPopulatorFactory,\n                        mSelectionDropdownMenuDelegate,\n                        mTabModelSelector,){2,}|\n                        mContextMenuPopulatorFactory,\n                        mSelectionDropdownMenuDelegate,\n                        mTabModelSelector,|g' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n                        mWindowAndroid,){2,}|\n                        mWindowAndroid,|g' "$MENU_COORDINATOR"
perl -0pi -e 's~(\n                        (?:mExtensionsToolbarBridge|extensionsToolbarBridge),)(?!\n                        mWindowAndroid,)~$1\n                        mWindowAndroid,~' "$MENU_COORDINATOR"
perl -0pi -e 's~(\n                        mWindowAndroid,)(?!\n                        mContextMenuPopulatorFactory,)~$1\n                        mContextMenuPopulatorFactory,\n                        mSelectionDropdownMenuDelegate,\n                        mTabModelSelector,~' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n                        contextMenuPopulatorFactory,\n                        selectionDropdownMenuDelegate,\n                        tabModelSelector,){2,}|\n                        contextMenuPopulatorFactory,\n                        selectionDropdownMenuDelegate,\n                        tabModelSelector,|g' "$TOOLBAR"
perl -0pi -e 's~(\n                        windowAndroid,\n)                        contextMenuPopulatorFactory,\n                        selectionDropdownMenuDelegate,\n                        tabModelSelector,\n(\s*(?:task|mTask),)~$1$2~g' "$TOOLBAR"
perl -0pi -e 's|(\n                        mExtensionsToolbarBridge,\n)                        windowAndroid,\n(\s*contextMenuPopulatorFactory,)|$1$2|g' "$TOOLBAR"
perl -0pi -e 's~(\n                        currentTabSupplier,\n                        tabCreator,\n                        mExtensionsToolbarBridge,)(?!\n                        contextMenuPopulatorFactory,)~$1\n                        contextMenuPopulatorFactory,\n                        selectionDropdownMenuDelegate,\n                        tabModelSelector,~' "$TOOLBAR"
perl -0pi -e 's|mExtensionsToolbarBridge,\n                        mMenuButtonPinningDelegate,\n                        contextMenuPopulatorFactory,\n                        selectionDropdownMenuDelegate,\n                        tabModelSelector,|mExtensionsToolbarBridge,\n                        contextMenuPopulatorFactory,\n                        selectionDropdownMenuDelegate,\n                        tabModelSelector,\n                        mMenuButtonPinningDelegate,|' "$TOOLBAR"
grep -q 'import android.app.Activity;' "$MENU_MEDIATOR" || sed -i '/import android.content.Context;/i\import android.app.Activity;' "$MENU_MEDIATOR"
grep -q 'import android.view.View;' "$MENU_MEDIATOR" || sed -i '/import android.graphics.Bitmap;/a\import android.view.View;' "$MENU_MEDIATOR"
grep -q 'org.chromium.build.annotations.Nullable' "$MENU_MEDIATOR" || sed -i '/import org.chromium.build.annotations.NullMarked;/a\import org.chromium.build.annotations.Nullable;' "$MENU_MEDIATOR"
grep -q 'org.chromium.chrome.browser.tabmodel.TabModelSelector' "$MENU_MEDIATOR" || sed -i '/import org.chromium.chrome.browser.tab.TabLaunchType;/a\import org.chromium.chrome.browser.tabmodel.TabModelSelector;' "$MENU_MEDIATOR"
grep -q 'org.chromium.chrome.browser.ui.extensions.ExtensionActionPopupContents' "$MENU_MEDIATOR" || sed -i '/import org.chromium.chrome.browser.ui.extensions.ExtensionActionContextMenuBridge;/a\import org.chromium.chrome.browser.ui.extensions.ExtensionActionPopupContents;' "$MENU_MEDIATOR"
grep -q 'org.chromium.components.embedder_support.contextmenu.ContextMenuPopulatorFactory' "$MENU_MEDIATOR" || sed -i '/import org.chromium.components.embedder_support.util.UrlConstants;/i\import org.chromium.components.embedder_support.contextmenu.ContextMenuPopulatorFactory;' "$MENU_MEDIATOR"
grep -q 'org.chromium.content_public.browser.selection.SelectionDropdownMenuDelegate' "$MENU_MEDIATOR" || sed -i '/import org.chromium.content_public.browser.LoadUrlParams;/a\import org.chromium.content_public.browser.selection.SelectionDropdownMenuDelegate;' "$MENU_MEDIATOR"
grep -q 'org.chromium.ui.base.WindowAndroid' "$MENU_MEDIATOR" || sed -i '/import org.chromium.ui.base.PageTransition;/a\import org.chromium.ui.base.WindowAndroid;' "$MENU_MEDIATOR"
grep -q 'private final WindowAndroid mWindowAndroid;' "$MENU_MEDIATOR" || sed -i '/private final Context mContext;/a\    private final WindowAndroid mWindowAndroid;\n    private final TabModelSelector mTabModelSelector;\n    private final @Nullable ContextMenuPopulatorFactory mContextMenuPopulatorFactory;\n    private final @Nullable SelectionDropdownMenuDelegate mSelectionDropdownMenuDelegate;' "$MENU_MEDIATOR"
grep -q 'mPendingActionAnchorView' "$MENU_MEDIATOR" || sed -i '/private final TabCreator mTabCreator;/a\\n    private @Nullable View mPendingActionAnchorView;\n    private @Nullable ExtensionActionPopup mActivePopup;\n    private @Nullable String mActivePopupActionId;' "$MENU_MEDIATOR"
perl -0pi -e 's|(\n            WindowAndroid windowAndroid,\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,){2,}|\n            WindowAndroid windowAndroid,\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,|g' "$MENU_MEDIATOR"
grep -q 'WindowAndroid windowAndroid,' "$MENU_MEDIATOR" || perl -0pi -e 's|(\n            TabCreator tabCreator,\n            ExtensionsToolbarBridge toolbarBridge,)|$1\n            WindowAndroid windowAndroid,\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,|' "$MENU_MEDIATOR"
perl -0pi -e 's|(\n        mWindowAndroid = windowAndroid;\n        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;){2,}|\n        mWindowAndroid = windowAndroid;\n        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;|g' "$MENU_MEDIATOR"
grep -q 'mWindowAndroid = windowAndroid;' "$MENU_MEDIATOR" || perl -0pi -e 's|(\n        mActionModels = actionModels;\n        mContext = context;\n)|$1        mWindowAndroid = windowAndroid;\n        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;\n|' "$MENU_MEDIATOR"
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
grep -q 'public void onActionPopupRequested(String actionId, long nativeHostPtr)' "$MENU_MEDIATOR" || perl -0pi -e 's|(\n    \@Override\n    public void onReady\(\) \{)|\n    \@Override\n    public void onActionPopupRequested(String actionId, long nativeHostPtr) {\n        showActionPopup(actionId, nativeHostPtr);\n    }\n\n    \@Override\n    public void onActionContextMenuRequested(String actionId) {\n        showActionContextMenu(actionId);\n    }\n\n    \@Override\n    public void hideActivePopup() {\n        closeActivePopup();\n    }\n\n    \@Override\n    public boolean hasActivePopup() {\n        return mActivePopup != null;\n    }\n$1|' "$MENU_MEDIATOR"
grep -q 'public void triggerPopup' "$BRIDGE" || perl -0pi -e 's|(    public void onActionUpdated\(int actionIndex\) \{\n        mObserver\.onActionUpdated\(actionIndex\);\n    \}\n)|$1\n    \@CalledByNative\n    public void triggerPopup(\@JniType("std::string") String actionId, long nativeHostPtr) {\n        mObserver.onActionPopupRequested(actionId, nativeHostPtr);\n    }\n\n    \@CalledByNative\n    public void showContextMenu(\@JniType("std::string") String actionId) {\n        mObserver.onActionContextMenuRequested(actionId);\n    }\n\n    \@CalledByNative\n    public void hideActivePopup() {\n        mObserver.hideActivePopup();\n    }\n\n    \@CalledByNative\n    public boolean hasActivePopup() {\n        return mObserver.hasActivePopup();\n    }\n\n|' "$BRIDGE"
perl -0pi -e 's|    /\*\*\n    \@CalledByNative\n    public void triggerPopup\(\@JniType\("std::string"\) String actionId, long nativeHostPtr\) \{\n        mObserver\.onActionPopupRequested\(actionId, nativeHostPtr\);\n    \}\n\n    \@CalledByNative\n    public void showContextMenu\(\@JniType\("std::string"\) String actionId\) \{\n        mObserver\.onActionContextMenuRequested\(actionId\);\n    \}\n\n    \@CalledByNative\n    public void hideActivePopup\(\) \{\n        mObserver\.hideActivePopup\(\);\n    \}\n\n    \@CalledByNative\n    public boolean hasActivePopup\(\) \{\n        return mObserver\.hasActivePopup\(\);\n    \}\n\n\n     \* Callback from native indicating that an extension has been updated\.|    /**\n     * Callback from native indicating that an extension has been updated.|' "$BRIDGE"
perl -0pi -e 's|\@CalledByNative\n    \@CalledByNative\n    public void triggerPopup|@CalledByNative\n    public void triggerPopup|' "$BRIDGE"
grep -q 'void onActionPopupRequested(String actionId, long nativeHostPtr);' "$BRIDGE" || sed -i '/void onActionUpdated(int actionIndex);/a\\n        /** Called when native created a popup host for a menu action. */\n        void onActionPopupRequested(String actionId, long nativeHostPtr);\n\n        /** Called when native wants to show fallback context menu for a menu action. */\n        void onActionContextMenuRequested(String actionId);\n\n        /** Called when active popup should be hidden. */\n        void hideActivePopup();\n\n        /** Returns whether there is an active popup. */\n        boolean hasActivePopup();' "$BRIDGE"
grep -q 'base/android/scoped_java_ref.h' "$ACTION_DELEGATE_H" || sed -i '/#include "base\/memory\/raw_ptr.h"/i\#include "base/android/scoped_java_ref.h"' "$ACTION_DELEGATE_H"
grep -q 'java_menu_object' "$ACTION_DELEGATE_H" || sed -i '/extensions::ExtensionsToolbarAndroid\* toolbar_android);/a\  ExtensionActionDelegateAndroid(\n      BrowserWindowInterface* browser,\n      const ToolbarActionsModel::ActionId& action_id,\n      extensions::ExtensionsToolbarAndroid* toolbar_android,\n      const base::android::JavaRef<jobject>& java_menu_object);' "$ACTION_DELEGATE_H"
grep -q 'java_menu_object_' "$ACTION_DELEGATE_H" || sed -i '/const raw_ptr<extensions::ExtensionsToolbarAndroid> toolbar_android_;/a\\n  // Optional Java menu bridge used when a popup was requested from the extensions menu.\n  const base::android::ScopedJavaGlobalRef<jobject> java_menu_object_;' "$ACTION_DELEGATE_H"
grep -q '#include "base/android/jni_android.h"' "$ACTION_DELEGATE_CC" || sed -i '/#include <utility>/a\\n#include "base/android/jni_android.h"' "$ACTION_DELEGATE_CC"
grep -q '#include <cstdint>' "$ACTION_DELEGATE_CC" || sed -i '/#include "chrome\/browser\/ui\/android\/extensions\/extension_action_delegate_android.h"/a\\n#include <cstdint>' "$ACTION_DELEGATE_CC"
perl -0pi -e 's~#pragma clang diagnostic push\n#pragma clang diagnostic ignored "-Wunused-function"\n#include "chrome/browser/ui/android/extensions/jni_headers/ExtensionsMenuBridge_jni.h"\n#pragma clang diagnostic pop~#include "chrome/browser/ui/android/extensions/jni_headers/ExtensionsMenuBridge_jni.h"~g; s~\n?DEFINE_JNI_ExtensionsMenuBridge\(\);?\n~\n~g' "$ACTION_DELEGATE_CC"
grep -q 'ExtensionsMenuBridge_jni.h' "$ACTION_DELEGATE_CC" || perl -0pi -e 's~(#include "chrome/browser/ui/extensions/extension_action_view_model.h"\n)~$1\n#include "chrome/browser/ui/android/extensions/jni_headers/ExtensionsMenuBridge_jni.h"\n~' "$ACTION_DELEGATE_CC"
perl -0pi -e 's~(?:#pragma clang diagnostic ignored "-Wunused-function"\n)*(#include "chrome/browser/ui/android/extensions/jni_headers/ExtensionsMenuBridge_jni.h"\n)~#pragma clang diagnostic ignored "-Wunused-function"\n$1~g' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|(ExtensionActionDelegateAndroid::ExtensionActionDelegateAndroid\(\n    BrowserWindowInterface\* browser,\n    const ToolbarActionsModel::ActionId& action_id,\n    extensions::ExtensionsToolbarAndroid\* toolbar_android,\n    const base::android::JavaRef<jobject>& java_menu_object\)\n    : browser_\(browser\),\n      action_id_\(action_id\),\n      toolbar_android_\(toolbar_android\),\n      java_menu_object_\(java_menu_object\) \{\}\n\n){2,}|$1|g' "$ACTION_DELEGATE_CC"
grep -q 'const base::android::JavaRef<jobject>& java_menu_object)' "$ACTION_DELEGATE_CC" || perl -0pi -e 's|ExtensionActionDelegateAndroid::ExtensionActionDelegateAndroid\(\n    BrowserWindowInterface\* browser,\n    const ToolbarActionsModel::ActionId& action_id,\n    extensions::ExtensionsToolbarAndroid\* toolbar_android\)\n    : browser_\(browser\),\n      action_id_\(action_id\),\n      toolbar_android_\(toolbar_android\) \{\}|ExtensionActionDelegateAndroid::ExtensionActionDelegateAndroid(\n    BrowserWindowInterface* browser,\n    const ToolbarActionsModel::ActionId& action_id,\n    extensions::ExtensionsToolbarAndroid* toolbar_android)\n    : browser_(browser),\n      action_id_(action_id),\n      toolbar_android_(toolbar_android) {}\n\nExtensionActionDelegateAndroid::ExtensionActionDelegateAndroid(\n    BrowserWindowInterface* browser,\n    const ToolbarActionsModel::ActionId& action_id,\n    extensions::ExtensionsToolbarAndroid* toolbar_android,\n    const base::android::JavaRef<jobject>& java_menu_object)\n    : browser_(browser),\n      action_id_(action_id),\n      toolbar_android_(toolbar_android),\n      java_menu_object_(java_menu_object) {}|' "$ACTION_DELEGATE_CC"
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

# search
sed -i 's|BASE_FEATURE(kOmniboxSiteSearch, DISABLED);|BASE_FEATURE(kOmniboxSiteSearch, ENABLED);|' components/omnibox/common/omnibox_features.cc

# playback
sed -i 's|#if BUILDFLAG(IS_ANDROID)|#if 0|' content/public/renderer/render_frame_media_playback_options.cc

# viewport
sed -i 's|constexpr gfx::Size kMinSize = {25, 25};|constexpr gfx::Size kMinSize = {256, 25};|' chrome/browser/ui/android/extensions/extension_action_popup_contents.cc
sed -i 's|<meta name="color-scheme" content="light dark">|&\n<meta name="viewport" content="width=device-width">|' chrome/browser/resources/extensions/extensions.html
sed -i 's|height: calc(var(--md-toolbar-height) + 58px);|height: calc(var(--md-toolbar-height) + 104px);|' chrome/browser/resources/extensions/extensions.html
sed -i 's|--extensions-card-width: 400px;|--extensions-card-width: 96%;|' chrome/browser/resources/extensions/item_list.css # card width
sed -i 's|--cr-toolbar-field-width: 680px;|--cr-toolbar-field-width: 96%;|' chrome/browser/resources/extensions/shared_vars.css # page content
sed -i 's|padding: 24px 60px 64px;|padding: 24px 0 64px;|' chrome/browser/resources/extensions/item_list.css # content wrapper
perl -0pi -e 's/#devDrawer\[expanded\] #buttonStrip \{\n  top: 0;\n\}/#devDrawer[expanded] #buttonStrip {\n  top: auto;\n}/' chrome/browser/resources/extensions/toolbar.css
perl -0pi -e 's/#devDrawer\[expanded\] \{\n  height: calc\(var\(--button-row-height\) \+ var\(--border-bottom-height\)\);\n\}/#devDrawer[expanded] {\n  height: auto;\n  min-height: calc(var(--button-row-height) + var(--border-bottom-height));\n}/' chrome/browser/resources/extensions/toolbar.css
perl -0pi -e 's/#buttonStrip \{\n  margin-inline-end: auto;\n  margin-inline-start: 24px;\n  padding: var\(--padding-top-bottom\) 0;\n  position: absolute;\n  top: calc\(var\(--button-row-height\) \* -1\);\n  transition: top var\(--drawer-transition\);\n  \/\* Prevent selection of the blank space between buttons\. \*\/\n  user-select: none;\n  width: 100%;\n\}/#buttonStrip {\n  box-sizing: border-box;\n  display: flex;\n  flex-wrap: wrap;\n  gap: 8px 12px;\n  margin-inline-end: auto;\n  margin-inline-start: 0;\n  padding: var(--padding-top-bottom) 24px;\n  position: static;\n  transition: top var(--drawer-transition);\n  user-select: none;\n  width: 100%;\n}/' chrome/browser/resources/extensions/toolbar.css
perl -0pi -e 's/#buttonStrip cr-button \{\n  margin-inline-end: 16px;\n\}/#buttonStrip cr-button {\n  margin-inline-end: 0;\n  max-width: 100%;\n}/' chrome/browser/resources/extensions/toolbar.css

# ext: install local zip/crx from developer mode
sed -i '/info.can_load_unpacked =/,/->HasAllowlistedExtension();/c\  info.can_load_unpacked = true;' chrome/browser/extensions/api/developer_private/profile_info_generator.cc
perl -0pi -e 's|  file_path = \*vp;\n#endif  // BUILDFLAG\(IS_ANDROID\)|  file_path = *vp;\n\n  base::FilePath local_unpacked_dir =\n      Profile::FromBrowserContext(browser_context())\n          ->GetPath()\n          .Append(FILE_PATH_LITERAL("Local Extension Install Files"))\n          .Append(FILE_PATH_LITERAL("Unpacked Folders"));\n  base::FilePath stable_file_path =\n      local_unpacked_dir.Append(file_path.BaseName());\n  if (base::CreateDirectory(local_unpacked_dir)) {\n    if (base::PathExists(stable_file_path)) {\n      base::DeletePathRecursively(stable_file_path);\n    }\n    if (base::CopyDirectory(file_path, stable_file_path, true)) {\n      file_path = stable_file_path;\n    }\n  }\n#endif  // BUILDFLAG(IS_ANDROID)|' chrome/browser/extensions/api/developer_private/developer_private_functions.cc
# ZIP installs become unpacked extensions. Keep their extracted files under
# the profile on Chromium branches that still gate this behind a feature flag.
sed -i 's/BASE_FEATURE(kExtensionsZipFileInstalledInProfileDir, base::FEATURE_DISABLED_BY_DEFAULT);/BASE_FEATURE(kExtensionsZipFileInstalledInProfileDir, base::FEATURE_ENABLED_BY_DEFAULT);/' extensions/common/extension_features.cc
sed -i 's/BASE_FEATURE(kExtensionsZipFileInstalledInProfileDir, "ExtensionsZipFileInstalledInProfileDir", base::FEATURE_DISABLED_BY_DEFAULT);/BASE_FEATURE(kExtensionsZipFileInstalledInProfileDir, "ExtensionsZipFileInstalledInProfileDir", base::FEATURE_ENABLED_BY_DEFAULT);/' extensions/common/extension_features.cc
sed -i '/#include "base\/functional\/callback_helpers.h"/a\#include "base/hash/sha1.h"\n#include "base/strings/string_number_conversions.h"' extensions/browser/zipfile_installer.cc
perl -0pi -e 's|  // Create the root of the unique directory for the \.zip file\.\n  base::FilePath::StringType dir_name =\n      zip_file\.RemoveExtension\(\)\.BaseName\(\)\.value\(\) \+ FILE_PATH_LITERAL\("_"\);\n\n  // Creates the full unique directory path as unzip_dir\.\n  base::FilePath unzip_dir;\n  if \(!base::CreateTemporaryDirInDir\(root_unzip_dir, dir_name, &unzip_dir\)\) \{\n    return ZipResultVariant\{ErrorUtils::FormatErrorMessage\(\n        kExtensionHandlerZippedDirError,\n        base::UTF16ToUTF8\(unzip_dir\.LossyDisplayName\(\)\)\)\};\n  \}|  std::string zip_contents;\n  if (!base::ReadFileToString(zip_file, \&zip_contents)) {\n    return ZipResultVariant{std::string(kExtensionHandlerFileUnzipError)};\n  }\n\n  std::string zip_hash =\n      base::HexEncodeLower(base::SHA1HashString(zip_contents)).substr(0, 12);\n  base::FilePath unzip_dir = root_unzip_dir.Append(\n      zip_file.RemoveExtension().BaseName().value() + FILE_PATH_LITERAL("_") +\n      base::FilePath::FromASCII(zip_hash).value());\n  if (base::PathExists(unzip_dir) \&\&\n      !base::DeletePathRecursively(unzip_dir)) {\n    return ZipResultVariant{ErrorUtils::FormatErrorMessage(\n        kExtensionHandlerZippedDirError,\n        base::UTF16ToUTF8(unzip_dir.LossyDisplayName()))};\n  }\n  if (!base::CreateDirectory(unzip_dir)) {\n    return ZipResultVariant{ErrorUtils::FormatErrorMessage(\n        kExtensionHandlerZippedDirError,\n        base::UTF16ToUTF8(unzip_dir.LossyDisplayName()))};\n  }|' extensions/browser/zipfile_installer.cc
sed -i '/loadUnpacked(): Promise<boolean>;/a\
  /** Opens a file picker to install a local zip, crx, or user script. */\
  installLocalExtensionFile(): Promise<boolean>;' chrome/browser/resources/extensions/toolbar.ts
sed -i '/loadUnpacked() {/i\
  installLocalExtensionFile() {\
    return Promise.resolve(false);\
  }' chrome/browser/resources/extensions/toolbar.ts
sed -i '/loadUnpacked: HTMLElement,/a\
    loadExtensionFile: HTMLElement,' chrome/browser/resources/extensions/toolbar.ts
sed -i '/protected onLoadUnpackedClick_()/i\
  protected onLoadExtensionFileClick_() {\
    this.delegate.installLocalExtensionFile()\
        .then((success) => {\
          if (success) {\
            const toastManager = getToastManager();\
            toastManager.duration = TOAST_DURATION_MS;\
            toastManager.show(this.i18n("toolbarLoadUnpackedDone"));\
          }\
        })\
        .catch(loadError => {\
          this.fire("load-error", loadError);\
        });\
    chrome.metricsPrivate.recordUserAction("Options_LoadLocalExtensionFile");\
  }\
' chrome/browser/resources/extensions/toolbar.ts
sed -i '/<cr-button ?hidden="${!this.canLoadUnpacked_()}" id="loadUnpacked"/i\
    <cr-button id="loadExtensionFile"\
        @click="${this.onLoadExtensionFileClick_}">\
      Load ZIP/CRX\
    </cr-button>' chrome/browser/resources/extensions/toolbar.html.ts
sed -i 's|<cr-button ?hidden="${!this.canLoadUnpacked_()}" id="loadUnpacked"|<cr-button id="loadUnpacked"|' chrome/browser/resources/extensions/toolbar.html.ts
sed -i '/protected canLoadUnpacked_()/,/^  }/c\
  protected canLoadUnpacked_() {\
    return true;\
  }' chrome/browser/resources/extensions/toolbar.ts
sed -i '/loadUnpacked(): Promise<boolean> {/i\
  installLocalExtensionFile(): Promise<boolean> {\
    return this.chooseFilePath_(\
        chrome.developerPrivate.SelectType.FILE,\
        chrome.developerPrivate.FileType.LOAD)\
        .then(path => {\
          if (!path) {\
            return false;\
          }\
          return Promise.resolve(chrome.developerPrivate.installDroppedFile())\
              .then(() => true);\
        });\
  }\
' chrome/browser/resources/extensions/service.ts
sed -i '/if (params->file_type == developer::FileType::kLoad) {/a\
    if (params->select_type == developer::SelectType::kFile) {\
      file_type_info.extensions.push_back({FILE_PATH_LITERAL("zip"),\
                                           FILE_PATH_LITERAL("crx"),\
                                           FILE_PATH_LITERAL("user.js")});\
      file_type_info.include_all_files = true;\
      file_type_index = 1;\
    }' chrome/browser/extensions/api/developer_private/developer_private_functions.cc
sed -i '/Respond(WithArguments(file.path().LossyDisplayName()));/i\
  base::FilePath selected_path = file.path();\
  ui::FileInfo display_file(selected_path, base::FilePath(file.display_name));\
  if (MatchesExtension(display_file, FILE_PATH_LITERAL(".zip")) ||\
      MatchesExtension(display_file, FILE_PATH_LITERAL(".crx")) ||\
      MatchesExtension(display_file, FILE_PATH_LITERAL(".user.js"))) {\
    base::FilePath selected_name = file.display_name.empty()\
        ? selected_path.BaseName()\
        : base::FilePath(file.display_name).BaseName();\
    base::FilePath dragged_path = selected_path;\
    base::FilePath persisted_dir;\
    base::FilePath local_extension_dir =\
        Profile::FromBrowserContext(browser_context())\
            ->GetPath()\
            .Append(FILE_PATH_LITERAL("Local Extension Install Files"));\
    if (base::CreateDirectory(local_extension_dir) &&\
        base::CreateTemporaryDirInDir(\
            local_extension_dir, FILE_PATH_LITERAL("install-"), &persisted_dir)) {\
      base::FilePath persisted_path = persisted_dir.Append(selected_name);\
      if (base::CopyFile(selected_path, persisted_path)) {\
        dragged_path = persisted_path;\
      } else {\
        base::DeletePathRecursively(persisted_dir);\
      }\
    }\
    ui::FileInfo selected_file(dragged_path, selected_name);\
    if (content::WebContents* web_contents = GetSenderWebContents()) {\
      DeveloperPrivateAPI::Get(browser_context())->SetDraggedFile(\
          web_contents, selected_file);\
    }\
  }' chrome/browser/extensions/api/developer_private/developer_private_functions.cc
perl -0pi -e 's|#if BUILDFLAG\(IS_ANDROID\)\n  base::expected<void, std::string> result =\n      SetDroppedPath\(web_contents, browser_context\(\)\);\n  if \(!result\.has_value\(\)\) \{\n    return RespondNow\(Error\(result\.error\(\)\)\);\n  \}\n#endif  // BUILDFLAG\(IS_ANDROID\)|#if BUILDFLAG(IS_ANDROID)\n  {\n    DeveloperPrivateAPI* api = DeveloperPrivateAPI::Get(browser_context());\n    ui::FileInfo file = api->GetDraggedFile(web_contents);\n    if (file.path.empty()) {\n      base::expected<void, std::string> result =\n          SetDroppedPath(web_contents, browser_context());\n      if (!result.has_value()) {\n        return RespondNow(Error(result.error()));\n      }\n    }\n  }\n#endif  // BUILDFLAG(IS_ANDROID)|' chrome/browser/extensions/api/developer_private/developer_private_functions.cc
perl -0pi -e 's|  if \(MatchesExtension\(file, FILE_PATH_LITERAL\("\.zip"\)\)\) \{\n    ExtensionRegistrar\* registrar = ExtensionRegistrar::Get\(browser_context\(\)\);\n    ZipFileInstaller::Create\(\n        GetExtensionFileTaskRunner\(\),\n        MakeRegisterInExtensionServiceCallback\(browser_context\(\)\)\)\n        ->InstallZipFileToUnpackedExtensionsDir\(\n            file\.path, registrar->unpacked_install_directory\(\)\);\n  \} else \{|  if (MatchesExtension(file, FILE_PATH_LITERAL(".zip"))) {\n    base::FilePath local_zip_unpacked_dir =\n        Profile::FromBrowserContext(browser_context())\n            ->GetPath()\n            .Append(FILE_PATH_LITERAL("Local Extension Install Files"))\n            .Append(FILE_PATH_LITERAL("Unpacked Extensions"));\n    ZipFileInstaller::Create(\n        GetExtensionFileTaskRunner(),\n        MakeRegisterInExtensionServiceCallback(browser_context()))\n        ->InstallZipFileToUnpackedExtensionsDir(file.path,\n                                                local_zip_unpacked_dir);\n  } else {|' chrome/browser/extensions/api/developer_private/developer_private_functions.cc

# ext: mv2
sed -i 's/BASE_FEATURE(kExtensionManifestV2Unsupported, base::FEATURE_ENABLED_BY_DEFAULT);/BASE_FEATURE(kExtensionManifestV2Unsupported, base::FEATURE_DISABLED_BY_DEFAULT);/' extensions/common/extension_features.cc
sed -i 's/BASE_FEATURE(kExtensionManifestV2Disabled, base::FEATURE_ENABLED_BY_DEFAULT);/BASE_FEATURE(kExtensionManifestV2Disabled, base::FEATURE_DISABLED_BY_DEFAULT);/' extensions/common/extension_features.cc
perl -0pi -e 's|bool ExtensionManagement::IsAllowedByUnpackedDeveloperModePolicy\(\n    const Extension& extension\) \{\n.*?\n\}\n\nbool ExtensionManagement::IsGreylistedForceInstalledInLowTrustEnvironment|bool ExtensionManagement::IsAllowedByUnpackedDeveloperModePolicy(\n    const Extension& extension) {\n  return true;\n}\n\nbool ExtensionManagement::IsGreylistedForceInstalledInLowTrustEnvironment|s' chrome/browser/extensions/extension_management.cc
sed -i 's|return IsFromStore(extension, context) && CanUseExtensionApis(extension);|return extension.from_webstore() \&\& CanUseExtensionApis(extension);|' extensions/browser/install_verifier.cc
perl -0pi -e 's|  if \(AllowedByEnterprisePolicy\(extension->id\(\)\) &&\n      !ExtensionsBrowserClient::Get\(\)\n           ->GetExtensionManagementClient\(context_\)\n           ->IsForceInstalledInLowTrustEnvironment\(\*extension\)\) \{\n    return false;\n  \}\n\n  bool verified = true;|  if (AllowedByEnterprisePolicy(extension->id()) &&\n      !ExtensionsBrowserClient::Get()\n           ->GetExtensionManagementClient(context_)\n           ->IsForceInstalledInLowTrustEnvironment(*extension)) {\n    return false;\n  }\n  if (!extension->from_webstore()) {\n    return false;\n  }\n\n  bool verified = true;|' extensions/browser/install_verifier.cc
sed -i 's|if (!InstallVerifier::IsFromStore(extension, context_)) {|if (!extension.from_webstore()) {|' chrome/browser/extensions/chrome_content_verifier_delegate.cc
perl -0pi -e 's/^\s+"proxy\.json",\n//mg; s/^(schema_sources_ = \[\n)/$1  "proxy.json",\n/' chrome/common/extensions/api/api_sources.gni
perl -0pi -e 's/^\s+"browser_action\.json",\n//mg; s/^\s+"page_action\.json",\n//mg; s/^(uncompiled_sources_ = \[\n)/$1  "browser_action.json",\n  "page_action.json",\n/' chrome/common/extensions/api/api_sources.gni
sed -i 's/api::webstore_private::MV2DeprecationStatus::kHardDisable)));/api::webstore_private::MV2DeprecationStatus::kNone)));/' chrome/browser/extensions/api/webstore_private/webstore_private_api.cc
sed -i 's/bool g_allow_mv2_for_testing = false;/bool g_allow_mv2_for_testing = true;/' extensions/browser/manifest_v2_experiment_manager.cc

# android: require explicit user confirmation before launching external apps
perl -0pi -e 's|            if \(debug\(\)\) Log\.i\(TAG, "startActivity"\);\n            context\.startActivity\(intent\);\n            recordExternalNavigationDispatched\(intent\);\n            mDelegate\.reportIntentToSafeBrowsing\(intent\);|            if (debug()) Log.i(TAG, "startActivity");\n            Intent launchIntent = intent;\n            if (!Intent.ACTION_CHOOSER.equals(intent.getAction())\n                    \&\& !Intent.ACTION_PICK_ACTIVITY.equals(intent.getAction())) {\n                launchIntent = Intent.createChooser(intent, null);\n            }\n            context.startActivity(launchIntent);\n            recordExternalNavigationDispatched(intent);\n            mDelegate.reportIntentToSafeBrowsing(intent);|' components/external_intents/android/java/src/org/chromium/components/external_intents/ExternalNavigationHandler.java

# ext: isolate top-level navigations from extension blockers
sed -i '/case DNRRequestAction::Type::BLOCK:/,/case DNRRequestAction::Type::ALLOW:/ s|ClearPendingCallbacks(browser_context, \*request);|if (request->web_request_type == WebRequestResourceType::MAIN_FRAME) { break; }\n          ClearPendingCallbacks(browser_context, *request);|' extensions/browser/api/web_request/extension_web_request_event_router.cc
sed -i '/case DNRRequestAction::Type::REDIRECT:/,/case DNRRequestAction::Type::MODIFY_HEADERS:/ s|ClearPendingCallbacks(browser_context, \*request);|if (request->web_request_type == WebRequestResourceType::MAIN_FRAME) { break; }\n          ClearPendingCallbacks(browser_context, *request);|' extensions/browser/api/web_request/extension_web_request_event_router.cc
grep -q 'Helium: ignore extension main-frame cancel/redirect' extensions/browser/api/web_request/extension_web_request_event_router.cc || sed -i '/  const bool redirected =/i\
  // Helium: ignore extension main-frame cancel/redirect results. Ad blockers\
  // can otherwise leave a restored startup tab with an empty WebContents.\
  if (request->web_request_type == WebRequestResourceType::MAIN_FRAME) {\
    canceled_by_extension.reset();\
    if (blocked_request.new_url \&\& !blocked_request.new_url->is_empty()) {\
      *blocked_request.new_url = GURL();\
    }\
  }\
' extensions/browser/api/web_request/extension_web_request_event_router.cc

# ext: keep early content-script injection from breaking page startup
sed -i '/extensions_features::kExtensionsBackgroundCompilation));/a\
  if (host_id_.type == mojom::HostID::HostType::kExtensions &&\
      web_frame->IsOutermostMainFrame() &&\
      !document_url.SchemeIs("chrome-extension")) {\
    return;\
  }' extensions/renderer/user_script_set.cc
sed -i '/  bool inject_css = !script->css_scripts().empty() &&/,/      !script->js_scripts().empty() && script->run_location() == run_location;/c\
  // Delay extension main-frame work until the page is idle. Dark-mode/style\
  // and filtering extensions can otherwise alter CSS or script state before\
  // the page initializes, leaving some sites blank. Keep\
  // extension pages at their declared timing so new-tab/homepage extensions\
  // such as iTabs can initialize normally.\
  const bool delay_main_frame_extension_scripts =\
      host_id_.type == mojom::HostID::HostType::kExtensions &&\
      web_frame->IsOutermostMainFrame() &&\
      !document_url.SchemeIs("chrome-extension");\
\
  mojom::RunLocation script_run_location = script->run_location();\
  if (delay_main_frame_extension_scripts &&\
      (script_run_location == mojom::RunLocation::kDocumentStart ||\
       script_run_location == mojom::RunLocation::kDocumentEnd)) {\
    script_run_location = mojom::RunLocation::kDocumentIdle;\
  }\
\
  const mojom::RunLocation css_run_location =\
      delay_main_frame_extension_scripts ? mojom::RunLocation::kDocumentIdle\
                                         : mojom::RunLocation::kDocumentStart;\
  bool inject_css =\
      !script->css_scripts().empty() && run_location == css_run_location;\
  bool inject_js =\
      !script->js_scripts().empty() && script_run_location == run_location;' extensions/renderer/user_script_set.cc

# ext: toolbar
sed -i '/<ViewStub/{N;N;N;N;N;N; /optional_button_stub/a\
        <ViewStub\
            android:id="@+id/extensions_toolbar_container_stub"\
            android:inflatedId="@+id/extensions_toolbar_container"\
            android:layout_width="wrap_content"\
            android:layout_height="match_parent" />
}' chrome/browser/ui/android/toolbar/java/res/layout/toolbar_phone.xml
sed -i 's|(ToolbarTablet) mToolbarLayout,|mToolbarLayout,|' chrome/android/java/src/org/chromium/chrome/browser/toolbar/ToolbarManager.java
sed -i '/\/\/ Draw the signin button if visible./i\        { View extContainer = findViewById(R.id.extensions_toolbar_container); if (extContainer != null \&\& extContainer.getVisibility() != View.GONE \&\& extContainer.getWidth() != 0) { canvas.save(); ViewUtils.translateCanvasToView(mToolbarButtonsContainer, extContainer, canvas); extContainer.draw(canvas); canvas.restore(); } }' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/top/ToolbarPhone.java

# ext: pin
perl -0pi -e 'if (!/setHeliumMenuButtonVisibility/) { s|    private void showIphInternal\(\) \{|    private void setHeliumMenuButtonVisibility(boolean visible) {\n        if (mContainer == null) return;\n        View menuButton = mContainer.findViewById(R.id.extensions_menu_button);\n        if (menuButton == null) return;\n        menuButton.setVisibility(visible ? View.VISIBLE : View.GONE);\n    }\n\n    private void showIphInternal() {| }' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
sed -i 's|if (mPrefService.getBoolean(Pref.PIN_EXTENSIONS_MENU_BUTTON)) { mContainer.findViewById(R.id.extensions_menu_button).setVisibility(View.VISIBLE); } else { mContainer.findViewById(R.id.extensions_menu_button).setVisibility(View.GONE); }|        setHeliumMenuButtonVisibility(mPrefService.getBoolean(Pref.PIN_EXTENSIONS_MENU_BUTTON));|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
sed -i 's|mContainer.findViewById(R.id.extensions_menu_button).setVisibility(isMenuButtonPinned() ? View.VISIBLE : View.GONE);|                setHeliumMenuButtonVisibility(isMenuButtonPinned());|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
sed -i '/Pref.PIN_EXTENSIONS_MENU_BUTTON, this::updateMenuButtonPinState);$/a\        setHeliumMenuButtonVisibility(mPrefService.getBoolean(Pref.PIN_EXTENSIONS_MENU_BUTTON));' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
sed -i '/"ExtensionsToolbarCoordinatorImpl.requestLayoutWithViewUtils()");$/a\                setHeliumMenuButtonVisibility(isMenuButtonPinned());' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
perl -0pi -e 's|        mContainer\.findViewById\(R\.id\.extensions_menu_button\)\.setVisibility\(visibility\);|        View menuButton = mContainer.findViewById(R.id.extensions_menu_button);\n        if (menuButton != null) {\n            menuButton.setVisibility(visibility);\n        }|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java

# ext: incognito
grep -q 'build/build_config.h' chrome/browser/ui/extensions/extensions_menu_view_model.cc || sed -i '/#include "base\/metrics\/user_metrics_action.h"/a\#include "build/build_config.h"' chrome/browser/ui/extensions/extensions_menu_view_model.cc
perl -0pi -e 's|  ExtensionsMenuViewModel::ControlState button_state;\n  button_state\.text = action_model->GetActionName\(\);|  ExtensionsMenuViewModel::ControlState button_state;\n#if BUILDFLAG(IS_ANDROID)\n  std::u16string action_title =\n      web_contents ? action_model->GetActionTitle(web_contents)\n                   : std::u16string();\n  button_state.text = action_title.empty() ? action_model->GetActionName()\n                                           : action_title;\n#else\n  button_state.text = action_model->GetActionName();\n#endif|' chrome/browser/ui/extensions/extensions_menu_view_model.cc

# Use the current Java tab when the Android extensions menu asks native for
# action state. The platform-agnostic menu model can otherwise resolve the
# active WebContents from the regular browser window while the visible tab is
# incognito, which makes per-tab action titles/icons (SwitchyOmega status) show
# the normal tab instead of the current incognito page.
grep -q 'org.chromium.content_public.browser.WebContents;' "$BRIDGE" || sed -i '/import org.chromium.chrome.browser.ui.browser_window.ChromeAndroidTask;/a\import org.chromium.content_public.browser.WebContents;' "$BRIDGE"
perl -0pi -e 's|public void executeAction\(String extensionId\) \{\n        ExtensionsMenuBridgeJni\.get\(\)\n                \.executeAction\(mNativeExtensionsMenuDelegateAndroid, extensionId\);\n    \}|public void executeAction(String extensionId) {\n        executeAction(extensionId, null);\n    }\n\n    public void executeAction(String extensionId, \@Nullable WebContents webContents) {\n        ExtensionsMenuBridgeJni.get()\n                .executeAction(mNativeExtensionsMenuDelegateAndroid, extensionId, webContents);\n    }|' "$BRIDGE"
perl -0pi -e 's|public \@Nullable Bitmap getActionIcon\(int actionIndex\) \{\n        return ExtensionsMenuBridgeJni\.get\(\)\n                \.getActionIcon\(mNativeExtensionsMenuDelegateAndroid, actionIndex\);\n    \}|public \@Nullable Bitmap getActionIcon(int actionIndex) {\n        return getActionIcon(actionIndex, null);\n    }\n\n    public \@Nullable Bitmap getActionIcon(int actionIndex, \@Nullable WebContents webContents) {\n        return ExtensionsMenuBridgeJni.get()\n                .getActionIcon(mNativeExtensionsMenuDelegateAndroid, actionIndex, webContents);\n    }|' "$BRIDGE"
perl -0pi -e 's|public List<ExtensionsMenuTypes\.MenuEntryState> getMenuEntries\(\) \{\n        return ExtensionsMenuBridgeJni\.get\(\)\.getMenuEntries\(mNativeExtensionsMenuDelegateAndroid\);\n    \}|public List<ExtensionsMenuTypes.MenuEntryState> getMenuEntries() {\n        return getMenuEntries(null);\n    }\n\n    public List<ExtensionsMenuTypes.MenuEntryState> getMenuEntries(\n            \@Nullable WebContents webContents) {\n        return ExtensionsMenuBridgeJni.get()\n                .getMenuEntries(mNativeExtensionsMenuDelegateAndroid, webContents);\n    }|' "$BRIDGE"
perl -0pi -e 's|public ExtensionsMenuTypes\.MenuEntryState getMenuEntry\(int actionIndex\) \{\n        return ExtensionsMenuBridgeJni\.get\(\)\n                \.getMenuEntry\(mNativeExtensionsMenuDelegateAndroid, actionIndex\);\n    \}|public ExtensionsMenuTypes.MenuEntryState getMenuEntry(int actionIndex) {\n        return getMenuEntry(actionIndex, null);\n    }\n\n    public ExtensionsMenuTypes.MenuEntryState getMenuEntry(\n            int actionIndex, \@Nullable WebContents webContents) {\n        return ExtensionsMenuBridgeJni.get()\n                .getMenuEntry(mNativeExtensionsMenuDelegateAndroid, actionIndex, webContents);\n    }|' "$BRIDGE"
perl -0pi -e 's|\@Nullable Bitmap getActionIcon\(long nativeExtensionsMenuDelegateAndroid, int actionIndex\);|\@Nullable Bitmap getActionIcon(\n                long nativeExtensionsMenuDelegateAndroid,\n                int actionIndex,\n                \@Nullable \@JniType("content::WebContents*") WebContents webContents);|' "$BRIDGE"
perl -0pi -e 's|void executeAction\(\n                long nativeExtensionsMenuDelegateAndroid,\n                \@JniType\("std::string"\) String extensionId\);|void executeAction(\n                long nativeExtensionsMenuDelegateAndroid,\n                \@JniType("std::string") String extensionId,\n                \@Nullable \@JniType("content::WebContents*") WebContents webContents);|' "$BRIDGE"
perl -0pi -e 's|List<ExtensionsMenuTypes\.MenuEntryState> getMenuEntries\(\n                long nativeExtensionsMenuDelegateAndroid\);|List<ExtensionsMenuTypes.MenuEntryState> getMenuEntries(\n                long nativeExtensionsMenuDelegateAndroid,\n                \@Nullable \@JniType("content::WebContents*") WebContents webContents);|' "$BRIDGE"
perl -0pi -e 's|ExtensionsMenuTypes\.MenuEntryState getMenuEntry\(\n                long nativeExtensionsMenuDelegateAndroid, int actionIndex\);|ExtensionsMenuTypes.MenuEntryState getMenuEntry(\n                long nativeExtensionsMenuDelegateAndroid,\n                int actionIndex,\n                \@Nullable \@JniType("content::WebContents*") WebContents webContents);|' "$BRIDGE"

grep -q 'org.chromium.build.annotations.Nullable' "$MENU_MEDIATOR" || sed -i '/import org.chromium.build.annotations.NullMarked;/a\import org.chromium.build.annotations.Nullable;' "$MENU_MEDIATOR"
grep -q 'org.chromium.chrome.browser.tabmodel.TabModel;' "$MENU_MEDIATOR" || sed -i '/import org.chromium.chrome.browser.tabmodel.TabModelSelector;/a\import org.chromium.chrome.browser.tabmodel.TabModel;' "$MENU_MEDIATOR"
grep -q 'private @Nullable WebContents getCurrentWebContents()' "$MENU_MEDIATOR" || sed -i '/private @ExtensionsMenuProperties.Page int getCurrentPage()/i\
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
sed -i 's|mMenuBridge.getMenuEntry(actionIndex)|mMenuBridge.getMenuEntry(actionIndex, getCurrentWebContents())|g' "$MENU_MEDIATOR"
sed -i 's|mMenuBridge.getMenuEntry(newIndex)|mMenuBridge.getMenuEntry(newIndex, getCurrentWebContents())|g' "$MENU_MEDIATOR"
sed -i 's|mMenuBridge.getActionIcon(actionIndex)|mMenuBridge.getActionIcon(actionIndex, getCurrentWebContents())|g' "$MENU_MEDIATOR"
sed -i 's|mMenuBridge.getMenuEntries()|mMenuBridge.getMenuEntries(getCurrentWebContents())|g' "$MENU_MEDIATOR"
perl -0pi -e 's|mMenuBridge\.executeAction\(extensionId\);|mMenuBridge.executeAction(extensionId, getCurrentWebContents());|g' "$MENU_MEDIATOR"
perl -0pi -e 's|mMenuBridge\.executeAction\(entry\.id\)(?!,)|mMenuBridge.executeAction(entry.id, getCurrentWebContents())|g' "$MENU_MEDIATOR"

grep -q 'namespace content {' "$MENU_DELEGATE_H" || sed -i '/namespace extensions {/i\
namespace content {\
class WebContents;\
}  // namespace content\
\
' "$MENU_DELEGATE_H"
perl -0pi -e 's|void ExecuteAction\(JNIEnv\* env, const extensions::ExtensionId& extension_id\);|void ExecuteAction(JNIEnv* env,\n                     const extensions::ExtensionId& extension_id,\n                     content::WebContents* web_contents);|' "$MENU_DELEGATE_H"
perl -0pi -e 's|base::android::ScopedJavaLocalRef<jobject> GetActionIcon\(JNIEnv\* env,\n                                                           int action_index\);|base::android::ScopedJavaLocalRef<jobject> GetActionIcon(\n      JNIEnv* env,\n      int action_index,\n      content::WebContents* web_contents);|' "$MENU_DELEGATE_H"
perl -0pi -e 's|base::android::ScopedJavaLocalRef<jobject> GetMenuEntry\(JNIEnv\* env,\n                                                          int action_index\);|base::android::ScopedJavaLocalRef<jobject> GetMenuEntry(\n      JNIEnv* env,\n      int action_index,\n      content::WebContents* web_contents);|' "$MENU_DELEGATE_H"
perl -0pi -e 's|std::vector<base::android::ScopedJavaLocalRef<jobject>> GetMenuEntries\(\n      JNIEnv\* env\);|std::vector<base::android::ScopedJavaLocalRef<jobject>> GetMenuEntries(\n      JNIEnv* env,\n      content::WebContents* web_contents);|' "$MENU_DELEGATE_H"

grep -q 'chrome/browser/tab_list/tab_list_interface.h' "$MENU_DELEGATE_CC" || sed -i '/#include "chrome\/browser\/ui\/android\/extensions\/extension_action_delegate_android.h"/a\#include "chrome/browser/tab_list/tab_list_interface.h"' "$MENU_DELEGATE_CC"
grep -q 'chrome/browser/ui/toolbar/toolbar_action_view_model.h' "$MENU_DELEGATE_CC" || sed -i '/#include "chrome\/browser\/ui\/extensions\/extensions_menu_view_model.h"/a\#include "chrome/browser/ui/toolbar/toolbar_action_view_model.h"' "$MENU_DELEGATE_CC"
grep -q 'components/tabs/public/tab_interface.h' "$MENU_DELEGATE_CC" || sed -i '/#include "chrome\/browser\/ui\/extensions\/extensions_menu_view_model.h"/a\#include "components/tabs/public/tab_interface.h"' "$MENU_DELEGATE_CC"
grep -q 'extensions/browser/extension_registry.h' "$MENU_DELEGATE_CC" || sed -i '/#include "components\/tabs\/public\/tab_interface.h"/a\#include "extensions/browser/extension_registry.h"' "$MENU_DELEGATE_CC"
perl -0pi -e 's|void ExtensionsMenuDelegateAndroid::ExecuteAction\(\n    JNIEnv\* env,\n    const extensions::ExtensionId& extension_id\) \{\n  menu_model_->ExecuteAction\(extension_id\);\n\}|void ExtensionsMenuDelegateAndroid::ExecuteAction(\n    JNIEnv* env,\n    const extensions::ExtensionId& extension_id,\n    content::WebContents* web_contents) {\n  if (web_contents) {\n    tabs::TabInterface* tab =\n        tabs::TabInterface::MaybeGetFromContents(web_contents);\n    BrowserWindowInterface* action_browser =\n        tab ? tab->GetBrowserWindowInterface() : nullptr;\n    TabListInterface* tab_list =\n        action_browser ? TabListInterface::From(action_browser) : nullptr;\n    extensions::ExtensionRegistry* registry =\n        action_browser\n            ? extensions::ExtensionRegistry::Get(action_browser->GetProfile())\n            : nullptr;\n    if (tab_list \&\& registry \&\&\n        registry->enabled_extensions().Contains(extension_id)) {\n      tab_list->ActivateTab(tab->GetHandle());\n      auto action_model = ExtensionActionViewModel::Create(\n          extension_id, action_browser,\n          std::make_unique<ExtensionActionDelegateAndroid>(\n              action_browser, extension_id, toolbar_android_, java_object_));\n      action_model->ExecuteUserAction(\n          ToolbarActionViewModel::InvocationSource::kMenuEntry);\n      return;\n    }\n  }\n\n  menu_model_->ExecuteAction(extension_id);\n}|' "$MENU_DELEGATE_CC"
perl -0pi -e 's|ScopedJavaLocalRef<jobject> ExtensionsMenuDelegateAndroid::GetActionIcon\(\n    JNIEnv\* env,\n    int action_index\) \{\n  ui::ImageModel icon_model =\n      menu_model_->GetActionIcon\(action_index, kActionIconSize\);\n  return ConvertToJavaBitmap\(icon_model\);\n\}|ScopedJavaLocalRef<jobject> ExtensionsMenuDelegateAndroid::GetActionIcon(\n    JNIEnv* env,\n    int action_index,\n    content::WebContents* web_contents) {\n  if (web_contents) {\n    const auto\& action_models = menu_model_->action_models();\n    CHECK_GE(action_index, 0);\n    CHECK_LT(static_cast<size_t>(action_index), action_models.size());\n    return ConvertToJavaBitmap(\n        action_models[action_index]->GetIcon(web_contents, kActionIconSize));\n  }\n\n  ui::ImageModel icon_model =\n      menu_model_->GetActionIcon(action_index, kActionIconSize);\n  return ConvertToJavaBitmap(icon_model);\n}|' "$MENU_DELEGATE_CC"
perl -0pi -e 's|ScopedJavaLocalRef<jobject> ExtensionsMenuDelegateAndroid::GetMenuEntry\(\n    JNIEnv\* env,\n    int action_index\) \{|ScopedJavaLocalRef<jobject> ExtensionsMenuDelegateAndroid::GetMenuEntry(\n    JNIEnv* env,\n    int action_index,\n    content::WebContents* web_contents) {|' "$MENU_DELEGATE_CC"
grep -q 'action_model->GetActionTitle(web_contents)' "$MENU_DELEGATE_CC" || perl -0pi -e 's|  ExtensionsMenuViewModel::MenuEntryState state =\n      menu_model_->GetMenuEntryState\(id, kActionIconSize\);\n|  ExtensionsMenuViewModel::MenuEntryState state =\n      menu_model_->GetMenuEntryState(id, kActionIconSize);\n  if (web_contents) {\n    std::u16string action_title = action_model->GetActionTitle(web_contents);\n    if (!action_title.empty()) {\n      state.action_button.text = action_title;\n    }\n    state.action_button.tooltip_text = action_model->GetTooltip(web_contents);\n    state.action_button.status =\n        action_model->IsEnabled(web_contents)\n            ? ExtensionsMenuViewModel::ControlState::Status::kEnabled\n            : ExtensionsMenuViewModel::ControlState::Status::kDisabled;\n    state.action_button.icon =\n        action_model->GetIcon(web_contents, kActionIconSize);\n    state.origin = web_contents->GetPrimaryMainFrame()->GetLastCommittedOrigin();\n  }\n|' "$MENU_DELEGATE_CC"
perl -0pi -e 's|std::u16string action_title = action_model->GetActionTitle\(web_contents\);\n    state\.action_button\.text = action_title\.empty\(\)\n                                   \? action_model->GetActionName\(\)\n                                   : action_title;|std::u16string action_title = action_model->GetActionTitle(web_contents);\n    if (!action_title.empty()) {\n      state.action_button.text = action_title;\n    }|' "$MENU_DELEGATE_CC"
perl -0pi -e 's|ExtensionsMenuDelegateAndroid::GetMenuEntries\(JNIEnv\* env\) \{|ExtensionsMenuDelegateAndroid::GetMenuEntries(\n    JNIEnv* env,\n    content::WebContents* web_contents) {|' "$MENU_DELEGATE_CC"
sed -i 's|GetMenuEntry(env, i)|GetMenuEntry(env, i, web_contents)|g' "$MENU_DELEGATE_CC"

perl -0pi -e 's|bool ExtensionPrefs::IsIncognitoEnabled\(const ExtensionId& extension_id\) const \{\n  return ReadPrefAsBooleanAndReturn\(extension_id, kPrefIncognitoEnabled\);\n\}|bool ExtensionPrefs::IsIncognitoEnabled(const ExtensionId& extension_id) const {\n#if BUILDFLAG(IS_ANDROID)\n  return true;\n#else\n  return ReadPrefAsBooleanAndReturn(extension_id, kPrefIncognitoEnabled);\n#endif\n}|' extensions/browser/extension_prefs.cc
perl -0pi -e 's|void ExtensionPrefs::SetIsIncognitoEnabled\(const ExtensionId& extension_id,\n                                           bool enabled\) \{\n  UpdateExtensionPref\(extension_id, kPrefIncognitoEnabled,\n                      base::Value\(enabled\)\);\n  extension_pref_value_map_->SetExtensionIncognitoState\(extension_id, enabled\);\n\}|void ExtensionPrefs::SetIsIncognitoEnabled(const ExtensionId& extension_id,\n                                           bool enabled) {\n#if BUILDFLAG(IS_ANDROID)\n  enabled = true;\n#endif\n  UpdateExtensionPref(extension_id, kPrefIncognitoEnabled,\n                      base::Value(enabled));\n  extension_pref_value_map_->SetExtensionIncognitoState(extension_id, enabled);\n}|' extensions/browser/extension_prefs.cc

# ext: priority
sed -i 's|host_contents_->SetColorProviderSource(NoOpColorProviderSource::Get());|&\nhost_contents_->SetPrimaryPageImportance(content::ChildProcessImportance::IMPORTANT, content::ChildProcessImportance::NORMAL);|' extensions/browser/extension_host.cc

# ext: perms prompt
sed -i '/content::WebContents\* web_contents = show_params->GetParentWebContents();/,/DCHECK(view_android);/{/GetParentWebContents/!d}' chrome/browser/ui/android/extensions/extension_install_dialog_view_android.cc
sed -i 's|view_android->GetWindowAndroid();|show_params->GetParentWindow();|' chrome/browser/ui/android/extensions/extension_install_dialog_view_android.cc

# tmp: config info
sed -i 's|if (!_omit_dex) {|if (_is_base_module \&\& !_omit_dex) {|' build/config/android/rules.gni

# tmp
sed -i 's/BASE_FEATURE(kAndroidSearchInSettings,"SearchInSettings", base::FEATURE_DISABLED_BY_DEFAULT);/BASE_FEATURE(kAndroidSearchInSettings,"SearchInSettings", base::FEATURE_ENABLED_BY_DEFAULT);/' chrome/browser/flags/android/chrome_feature_list.cc
perl -0pi -e 's|current_toolchain == default_toolchain,|current_toolchain == default_toolchain \|\|\n        current_toolchain == "//build/toolchain/android:android_clang_arm64_webview",|' build/timestamp.gni
for file in components/omnibox/browser/autocomplete_match.h components/omnibox/browser/autocomplete_match.cc components/omnibox/browser/actions/omnibox_action.h components/omnibox/browser/location_bar_model_impl.cc components/omnibox/browser/location_bar_model_util.cc; do
sed -i '/#include "build\/build_config.h"/i #include "build/android_buildflags.h"' $file
sed -i 's/#if (!BUILDFLAG(IS_ANDROID) || BUILDFLAG(ENABLE_VR)) && !BUILDFLAG(IS_IOS)/#if (!BUILDFLAG(IS_ANDROID) || BUILDFLAG(ENABLE_VR) || BUILDFLAG(IS_DESKTOP_ANDROID)) \&\& !BUILDFLAG(IS_IOS)/' $file
done
sed -i 's/if ((!is_android || enable_vr) && !is_ios) {/if ((!is_android || enable_vr || is_desktop_android) \&\& !is_ios) {/' components/omnibox/browser/BUILD.gn

# crbug.com/40831291: bottom address bar
sed -i 's@(idealFitsBelow && spaceBelowAnchor >= spaceAboveAnchor) || !idealFitsAbove;@(idealFitsBelow == idealFitsAbove) ? (spaceBelowAnchor >= spaceAboveAnchor) : idealFitsBelow;@' ui/android/java/src/org/chromium/ui/widget/PopupSpecCalculator.java

# crbug.com/404069963: ntp override
sed -i 's/BASE_FEATURE(kChromeNativeUrlOverriding, base::FEATURE_DISABLED_BY_DEFAULT);/BASE_FEATURE(kChromeNativeUrlOverriding, base::FEATURE_ENABLED_BY_DEFAULT);/' chrome/browser/flags/android/chrome_feature_list.cc
sed -i 's|newCachedFlag(CHROME_NATIVE_URL_OVERRIDING, BuildConfig.IS_DESKTOP_ANDROID)|newCachedFlag(CHROME_NATIVE_URL_OVERRIDING, true)|' chrome/browser/flags/android/java/src/org/chromium/chrome/browser/flags/ChromeFeatureList.java

# crbug.com/helium: expose per-site forced dark mode in the app menu
perl -0pi -e 's/BASE_FEATURE\(kDarkenWebsitesCheckboxInThemesSetting,\n\s*base::FEATURE_DISABLED_BY_DEFAULT\);/BASE_FEATURE(kDarkenWebsitesCheckboxInThemesSetting,\n             base::FEATURE_ENABLED_BY_DEFAULT);/' components/content_settings/core/common/features.cc
perl -0pi -e 's/^[ \t]*return currentTab != null && !isNativePage && isFlagEnabled && isFeatureEnabled;\n/        return currentTab != null && !isNativePage;\n/m; s/^[ \t]*return currentTab != null[^\n]*isFeatureEnabled[^\n]*!isNativePage;\n/        return currentTab != null && !isNativePage;\n/m' chrome/android/java/src/org/chromium/chrome/browser/app/appmenu/AppMenuPropertiesDelegateImpl.java

# crbug.com/helium: do not let pages block tab close/navigation with beforeunload
grep -q 'Helium: beforeunload dialogs are disabled by default' components/javascript_dialogs/app_modal_dialog_manager.cc || sed -i '/void AppModalDialogManager::RunBeforeUnloadDialog(/,/^[}]$/ { /ChromeJavaScriptDialogExtraData\* extra_data =/i\
  // Helium: beforeunload dialogs are disabled by default.\
  std::move(callback).Run(true, std::u16string());\
  return;\

}' components/javascript_dialogs/app_modal_dialog_manager.cc

# crbug.com/helium: allow forcing site-requested new tabs/windows into current tab
if [ -f chrome/browser/ungoogled_flag_entries.h ] && ! grep -q '"open-new-links-in-current-tab"' chrome/browser/ungoogled_flag_entries.h; then
sed -i '/SINGLE_VALUE_TYPE("popups-to-tabs")},/a\
    {"open-new-links-in-current-tab",\
     "Open new links in current tab",\
     "Forces site-requested new tabs and windows to navigate in the current tab. ungoogled-chromium flag",\
     kOsAll, SINGLE_VALUE_TYPE("open-new-links-in-current-tab")},' chrome/browser/ungoogled_flag_entries.h
elif [ ! -f chrome/browser/ungoogled_flag_entries.h ] && ! grep -q '"open-new-links-in-current-tab"' chrome/browser/about_flags.cc; then
sed -i '/#include "chrome\/browser\/unexpire_flags_gen.inc"/a\
    {"open-new-links-in-current-tab",\
     "Open new links in current tab",\
     "Forces site-requested new tabs and windows to navigate in the current tab.",\
     kOsAndroid, SINGLE_VALUE_TYPE("open-new-links-in-current-tab")},' chrome/browser/about_flags.cc
fi
grep -q '#include "base/command_line.h"' content/renderer/render_frame_impl.cc || sed -i '0,/^#include /s|^#include |#include "base/command_line.h"\n#include |' content/renderer/render_frame_impl.cc
if ! grep -q 'open-new-links-in-current-tab' content/renderer/render_frame_impl.cc; then
sed -i '/case blink::kWebNavigationPolicyNewBackgroundTab:/,/return WindowOpenDisposition::NEW_BACKGROUND_TAB;/ s|return WindowOpenDisposition::NEW_BACKGROUND_TAB;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n        return WindowOpenDisposition::CURRENT_TAB;\n      return WindowOpenDisposition::NEW_BACKGROUND_TAB;|' content/renderer/render_frame_impl.cc
sed -i '/case blink::kWebNavigationPolicyNewForegroundTab:/,/return WindowOpenDisposition::NEW_FOREGROUND_TAB;/ s|return WindowOpenDisposition::NEW_FOREGROUND_TAB;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n        return WindowOpenDisposition::CURRENT_TAB;\n      return WindowOpenDisposition::NEW_FOREGROUND_TAB;|' content/renderer/render_frame_impl.cc
sed -i '/case blink::kWebNavigationPolicyNewWindow:/,/return WindowOpenDisposition::NEW_WINDOW;/ s|return WindowOpenDisposition::NEW_WINDOW;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n        return WindowOpenDisposition::CURRENT_TAB;\n      return WindowOpenDisposition::NEW_WINDOW;|' content/renderer/render_frame_impl.cc
sed -i '/case blink::kWebNavigationPolicyNewPopup:/,/return WindowOpenDisposition::NEW_POPUP;/ s|return WindowOpenDisposition::NEW_POPUP;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n        return WindowOpenDisposition::CURRENT_TAB;\n      return WindowOpenDisposition::NEW_POPUP;|' content/renderer/render_frame_impl.cc
fi
grep -q '#include "base/command_line.h"' ui/base/mojom/window_open_disposition_mojom_traits.h || sed -i '0,/^#include /s|^#include |#include "base/command_line.h"\n#include |' ui/base/mojom/window_open_disposition_mojom_traits.h
if ! grep -q 'open-new-links-in-current-tab' ui/base/mojom/window_open_disposition_mojom_traits.h; then
sed -i '/case WindowOpenDisposition::NEW_FOREGROUND_TAB:/,/return ui::mojom::WindowOpenDisposition::NEW_FOREGROUND_TAB;/ s|return ui::mojom::WindowOpenDisposition::NEW_FOREGROUND_TAB;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return ui::mojom::WindowOpenDisposition::CURRENT_TAB;\n        return ui::mojom::WindowOpenDisposition::NEW_FOREGROUND_TAB;|' ui/base/mojom/window_open_disposition_mojom_traits.h
sed -i '/case WindowOpenDisposition::NEW_BACKGROUND_TAB:/,/return ui::mojom::WindowOpenDisposition::NEW_BACKGROUND_TAB;/ s|return ui::mojom::WindowOpenDisposition::NEW_BACKGROUND_TAB;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return ui::mojom::WindowOpenDisposition::CURRENT_TAB;\n        return ui::mojom::WindowOpenDisposition::NEW_BACKGROUND_TAB;|' ui/base/mojom/window_open_disposition_mojom_traits.h
sed -i '/case WindowOpenDisposition::NEW_POPUP:/,/return ui::mojom::WindowOpenDisposition::NEW_POPUP;/ s|return ui::mojom::WindowOpenDisposition::NEW_POPUP;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return ui::mojom::WindowOpenDisposition::CURRENT_TAB;\n        return ui::mojom::WindowOpenDisposition::NEW_POPUP;|' ui/base/mojom/window_open_disposition_mojom_traits.h
sed -i '/case WindowOpenDisposition::NEW_WINDOW:/,/return ui::mojom::WindowOpenDisposition::NEW_WINDOW;/ s|return ui::mojom::WindowOpenDisposition::NEW_WINDOW;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return ui::mojom::WindowOpenDisposition::CURRENT_TAB;\n        return ui::mojom::WindowOpenDisposition::NEW_WINDOW;|' ui/base/mojom/window_open_disposition_mojom_traits.h
sed -i '/case ui::mojom::WindowOpenDisposition::NEW_FOREGROUND_TAB:/,/return WindowOpenDisposition::NEW_FOREGROUND_TAB;/ s|return WindowOpenDisposition::NEW_FOREGROUND_TAB;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return WindowOpenDisposition::CURRENT_TAB;\n        return WindowOpenDisposition::NEW_FOREGROUND_TAB;|' ui/base/mojom/window_open_disposition_mojom_traits.h
sed -i '/case ui::mojom::WindowOpenDisposition::NEW_BACKGROUND_TAB:/,/return WindowOpenDisposition::NEW_BACKGROUND_TAB;/ s|return WindowOpenDisposition::NEW_BACKGROUND_TAB;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return WindowOpenDisposition::CURRENT_TAB;\n        return WindowOpenDisposition::NEW_BACKGROUND_TAB;|' ui/base/mojom/window_open_disposition_mojom_traits.h
sed -i '/case ui::mojom::WindowOpenDisposition::NEW_POPUP:/,/return WindowOpenDisposition::NEW_POPUP;/ s|return WindowOpenDisposition::NEW_POPUP;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return WindowOpenDisposition::CURRENT_TAB;\n        return WindowOpenDisposition::NEW_POPUP;|' ui/base/mojom/window_open_disposition_mojom_traits.h
sed -i '/case ui::mojom::WindowOpenDisposition::NEW_WINDOW:/,/return WindowOpenDisposition::NEW_WINDOW;/ s|return WindowOpenDisposition::NEW_WINDOW;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          return WindowOpenDisposition::CURRENT_TAB;\n        return WindowOpenDisposition::NEW_WINDOW;|' ui/base/mojom/window_open_disposition_mojom_traits.h
sed -i '/case ui::mojom::WindowOpenDisposition::NEW_FOREGROUND_TAB:/,/return true;/ s|return true;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          *out = WindowOpenDisposition::CURRENT_TAB;\n        return true;|' ui/base/mojom/window_open_disposition_mojom_traits.h
sed -i '/case ui::mojom::WindowOpenDisposition::NEW_BACKGROUND_TAB:/,/return true;/ s|return true;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          *out = WindowOpenDisposition::CURRENT_TAB;\n        return true;|' ui/base/mojom/window_open_disposition_mojom_traits.h
sed -i '/case ui::mojom::WindowOpenDisposition::NEW_POPUP:/,/return true;/ s|return true;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          *out = WindowOpenDisposition::CURRENT_TAB;\n        return true;|' ui/base/mojom/window_open_disposition_mojom_traits.h
sed -i '/case ui::mojom::WindowOpenDisposition::NEW_WINDOW:/,/return true;/ s|return true;|if (base::CommandLine::ForCurrentProcess()->HasSwitch("open-new-links-in-current-tab"))\n          *out = WindowOpenDisposition::CURRENT_TAB;\n        return true;|' ui/base/mojom/window_open_disposition_mojom_traits.h
fi
grep -q '#include "base/command_line.h"' content/browser/web_contents/web_contents_impl.cc || sed -i '0,/^#include /s|^#include |#include "base/command_line.h"\n#include |' content/browser/web_contents/web_contents_impl.cc
if ! grep -q 'Helium: force new-tab OpenURL dispositions into current tab' content/browser/web_contents/web_contents_impl.cc; then
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

}' content/browser/web_contents/web_contents_impl.cc
fi

# crbug.com/helium: disable tab close undo snackbar
grep -q 'Helium: disable tab close undo snackbar' chrome/android/java/src/org/chromium/chrome/browser/undo_tab_close_snackbar/UndoBarController.java || sed -i '/if (closedTabs.isEmpty() && savedTabGroupSyncIds.isEmpty()) return;/a\
        if (shouldDisableUndoSnackbar()) {\
            for (Tab closedTab : closedTabs) {\
                commitTabClosure(closedTab.getId());\
            }\
            return;\
        }' chrome/android/java/src/org/chromium/chrome/browser/undo_tab_close_snackbar/UndoBarController.java
grep -q 'private static boolean shouldDisableUndoSnackbar' chrome/android/java/src/org/chromium/chrome/browser/undo_tab_close_snackbar/UndoBarController.java || sed -i '/private void showUndoBar(/i\
    private static boolean shouldDisableUndoSnackbar() {\
        // Helium: disable tab close undo snackbar.\
        return true;\
    }\
' chrome/android/java/src/org/chromium/chrome/browser/undo_tab_close_snackbar/UndoBarController.java

# crbug.com/helium: startup blank-screen recovery guards
sed -i '/import org.chromium.components.embedder_support.util.UrlUtilities;/i\
import org.chromium.components.embedder_support.util.UrlConstants;' chrome/android/java/src/org/chromium/chrome/browser/tabmodel/TabPersistentStoreImpl.java
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
    }' chrome/android/java/src/org/chromium/chrome/browser/tabmodel/TabPersistentStoreImpl.java
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
        }' chrome/android/java/src/org/chromium/chrome/browser/tabmodel/TabPersistentStoreImpl.java
perl -0pi -e 's|    \@Override\n    public void onStartWithNative\(\) \{|    private void clearVolatileRendererCaches() {\n        PostTask.postTask(\n                TaskTraits.BEST_EFFORT_MAY_BLOCK,\n                () -> {\n                    try {\n                        String dataDir = org.chromium.base.PathUtils.getDataDirectory();\n                        String[] paths = {\n                            "Default/GPUCache",\n                            "Default/GrShaderCache",\n                            "Default/ShaderCache",\n                            "Default/Code Cache/js",\n                            "Default/Code Cache/wasm"\n                        };\n                        for (String path : paths) {\n                            org.chromium.base.FileUtils.recursivelyDeleteFile(\n                                    new java.io.File(dataDir, path),\n                                    org.chromium.base.FileUtils.DELETE_ALL);\n                        }\n                    } catch (Throwable t) {\n                        Log.w(TAG, "Failed to clear volatile renderer caches", t);\n                    }\n                });\n    }\n\n    \@Override\n    public void onStartWithNative() {|' chrome/android/java/src/org/chromium/chrome/browser/ChromeTabbedActivity.java
# Keep the cache cleanup helper available for emergency debugging, but do not
# run it automatically on every startup. Deleting renderer caches while native
# startup is still settling can destabilize the first launch after install.

# crbug.com/431004500: incognito uaf
sed -i '/for (int i = 0; i < tab_list->GetTabCount(); ++i) {/i if (!tab_list) { continue; }' chrome/browser/extensions/api/tabs/tabs_api.cc

# crbug.com/40274462: incognito uaf
sed -i '/CONTENT_EXPORT static WebContents\* FromRenderFrameHost(RenderFrameHost\* rfh);/a\CONTENT_EXPORT static bool HasLiveWebContentsForBrowserContext(BrowserContext* browser_context);' content/public/browser/web_contents.h
sed -i '/^WebContentsImpl::WebContentsImpl(BrowserContext\* browser_context)/i\ bool WebContents::HasLiveWebContentsForBrowserContext(BrowserContext* browser_context) { for (WebContentsImpl* web_contents : WebContentsImpl::GetAllWebContents()) { if (web_contents->GetBrowserContext() == browser_context) { return true; } } return false; }' content/browser/web_contents/web_contents_impl.cc
sed -i '/#include "content\/public\/browser\/render_process_host.h"/a#include "content/public/browser/web_contents.h"' chrome/browser/profiles/profile_destroyer.cc
sed -i '/^void ProfileDestroyer::DestroyOTRProfileWhenAppropriateWithTimeout($/,/MaybeSendDestroyedNotification/{/  profile->MaybeSendDestroyedNotification();/i\
if (content::WebContents::HasLiveWebContentsForBrowserContext(profile)) { return; }
}' chrome/browser/profiles/profile_destroyer.cc

# crbug.com/444024982: api 31
sed -i 's/|| mSupportedProfileType == SupportedProfileType.REGULAR) {/|| mSupportedProfileType == SupportedProfileType.REGULAR || mSupportedProfileType == SupportedProfileType.MIXED) {/' chrome/android/java/src/org/chromium/chrome/browser/ChromeTabbedActivity.java
sed -i 's/|| mSupportedProfileType == SupportedProfileType.OFF_THE_RECORD) {/|| mSupportedProfileType == SupportedProfileType.OFF_THE_RECORD || mSupportedProfileType == SupportedProfileType.MIXED) {/' chrome/android/java/src/org/chromium/chrome/browser/ChromeTabbedActivity.java

export PATCHED=1

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
