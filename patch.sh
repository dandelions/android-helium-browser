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
sed -i '/#include "chrome\/browser\/extensions\/extension_view_host_factory.h"/a\#include "chrome/browser/extensions/extension_tab_util.h"\n#include "chrome/browser/profiles/profile.h"\n#include "chrome/browser/ui/browser_window/public/browser_window_interface.h"\n#include "extensions/browser/extension_registry.h"' chrome/browser/ui/android/extensions/extension_action_delegate_android.cc
perl -0pi -e 's|void ExtensionActionDelegateAndroid::ShowContextMenuAsFallback\(\) \{\n  const extensions::Extension\* extension =\n      extensions::ExtensionRegistry::Get\(browser_->GetProfile\(\)\)\n          ->enabled_extensions\(\)\n          \.GetByID\(action_id_\);\n  if \(extension &&\n      extensions::ExtensionTabUtil::OpenOptionsPage\(extension, browser_\)\) \{\n    return;\n  \}\n\n  toolbar_android_->ShowContextMenu\(action_id_\);\n\}|void ExtensionActionDelegateAndroid::ShowContextMenuAsFallback() {\n  toolbar_android_->ShowContextMenu(action_id_);\n}|' chrome/browser/ui/android/extensions/extension_action_delegate_android.cc

# Menu action popups should be anchored to the clicked menu row, not by
# temporarily popping the extension action into the toolbar.
BRIDGE=chrome/browser/ui/android/extensions/java/src/org/chromium/chrome/browser/ui/extensions/ExtensionsMenuBridge.java
MENU_MEDIATOR=chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
MENU_COORDINATOR=chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuCoordinator.java
TOOLBAR=chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
MENU_DELEGATE_CC=chrome/browser/ui/android/extensions/extensions_menu_delegate_android.cc
ACTION_DELEGATE_CC=chrome/browser/ui/android/extensions/extension_action_delegate_android.cc
ACTION_DELEGATE_H=chrome/browser/ui/android/extensions/extension_action_delegate_android.h
ACTION_LIST_MEDIATOR=chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionActionListMediator.java
perl -0pi -e 's|if \(hasPoppedOutAction\(\)\) \{\n            mCanShowPoppedOutAction = true;\n            return itemWidth;\n        \} else \{\n            mCanShowPoppedOutAction = false;\n            return 0;\n        \}|if (hasPoppedOutAction() && itemWidth <= availableWidth) {\n            mCanShowPoppedOutAction = true;\n            return itemWidth;\n        } else {\n            mCanShowPoppedOutAction = false;\n            return 0;\n        }|' "$ACTION_LIST_MEDIATOR"
perl -0pi -e 's|if \(findIndexForId\(actionId\) == -1\) \{\n            mPoppedOutActionId = actionId;\n            mCanShowPoppedOutAction = true;\n            reconcileActionItems\(\);\n        \}|if (findIndexForId(actionId) == -1) {\n            mPoppedOutActionId = actionId;\n        }|' "$ACTION_LIST_MEDIATOR"
grep -q 'org.chromium.chrome.browser.tabmodel.TabModelSelector' "$MENU_COORDINATOR" || sed -i '/import org.chromium.chrome.browser.tabmodel.TabCreator;/a\import org.chromium.chrome.browser.tabmodel.TabModelSelector;' "$MENU_COORDINATOR"
grep -q 'org.chromium.components.embedder_support.contextmenu.ContextMenuPopulatorFactory' "$MENU_COORDINATOR" || sed -i '/import org.chromium.chrome.browser.user_education.UserEducationHelper;/a\import org.chromium.components.embedder_support.contextmenu.ContextMenuPopulatorFactory;' "$MENU_COORDINATOR"
grep -q 'org.chromium.content_public.browser.selection.SelectionDropdownMenuDelegate' "$MENU_COORDINATOR" || sed -i '/import org.chromium.content_public.browser.WebContents;/a\import org.chromium.content_public.browser.selection.SelectionDropdownMenuDelegate;' "$MENU_COORDINATOR"
grep -q 'mContextMenuPopulatorFactory' "$MENU_COORDINATOR" || sed -i '/private final TabCreator mTabCreator;/a\    private final @Nullable ContextMenuPopulatorFactory mContextMenuPopulatorFactory;\n    private final @Nullable SelectionDropdownMenuDelegate mSelectionDropdownMenuDelegate;\n    private final TabModelSelector mTabModelSelector;' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n            TabCreator tabCreator,\n            ExtensionsToolbarBridge extensionsToolbarBridge,)|$1\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,|' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n        mTabCreator = tabCreator;\n        mTask = task;\n        mProfile = profile;\n)|        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;\n$1|' "$MENU_COORDINATOR"
grep -q 'mContextMenuPopulatorFactory = contextMenuPopulatorFactory;' "$MENU_COORDINATOR" || sed -i '/mExtensionsToolbarBridge = extensionsToolbarBridge;/a\        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n                        currentTabSupplier,\n                        tabCreator,\n                        mExtensionsToolbarBridge,)|$1\n                        mContextMenuPopulatorFactory,\n                        mSelectionDropdownMenuDelegate,\n                        mTabModelSelector,|' "$MENU_COORDINATOR"
perl -0pi -e 's|(\n                        currentTabSupplier,\n                        tabCreator,\n                        mExtensionsToolbarBridge,)|$1\n                        contextMenuPopulatorFactory,\n                        selectionDropdownMenuDelegate,\n                        tabModelSelector,|' "$TOOLBAR"
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
perl -0pi -e 's|(\n            TabCreator tabCreator,\n            ExtensionsToolbarBridge toolbarBridge,)|$1\n            WindowAndroid windowAndroid,\n            \@Nullable ContextMenuPopulatorFactory contextMenuPopulatorFactory,\n            \@Nullable SelectionDropdownMenuDelegate selectionDropdownMenuDelegate,\n            TabModelSelector tabModelSelector,|' "$MENU_MEDIATOR"
perl -0pi -e 's|(\n        mActionModels = actionModels;\n        mContext = context;\n)|$1        mWindowAndroid = windowAndroid;\n        mContextMenuPopulatorFactory = contextMenuPopulatorFactory;\n        mSelectionDropdownMenuDelegate = selectionDropdownMenuDelegate;\n        mTabModelSelector = tabModelSelector;\n|' "$MENU_MEDIATOR"
perl -0pi -e 's|(mMenuBridge\.destroy\(\);\n    \})|closeActivePopup();\n        $1|' "$MENU_MEDIATOR"
perl -0pi -e 's|(?:\s*closeActivePopup\(\);\n)+(\s*mMenuBridge\.destroy\(\);)|\n        closeActivePopup();\n$1|' "$MENU_MEDIATOR"
sed -i 's|(view) -> mMenuBridge.executeAction(entry.id))|(view) -> onPrimaryActionClicked(view, entry.id))|' "$MENU_MEDIATOR"
sed -i 's|(view) -> openExtensionFromMenu(entry.id))|(view) -> onPrimaryActionClicked(view, entry.id))|' "$MENU_MEDIATOR"
sed -i 's|(view) -> openUrlFromMenu(UrlConstants.CHROME_EXTENSIONS_ID_URL + entry.id))|(view) -> onPrimaryActionClicked(view, entry.id))|' "$MENU_MEDIATOR"
sed -i 's|(view) -> openExtensionOptionsFromMenu(entry.id))|(view) -> onPrimaryActionClicked(view, entry.id))|' "$MENU_MEDIATOR"
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
grep -q 'ExtensionsMenuBridge_jni.h' "$ACTION_DELEGATE_CC" || sed -i '/#include "chrome\/browser\/ui\/extensions\/extension_action_view_model.h"/a\\n#include "chrome/browser/ui/android/extensions/jni_headers/ExtensionsMenuBridge_jni.h"' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|ExtensionActionDelegateAndroid::ExtensionActionDelegateAndroid\(\n    BrowserWindowInterface\* browser,\n    const ToolbarActionsModel::ActionId& action_id,\n    extensions::ExtensionsToolbarAndroid\* toolbar_android\)\n    : browser_\(browser\),\n      action_id_\(action_id\),\n      toolbar_android_\(toolbar_android\) \{\}|ExtensionActionDelegateAndroid::ExtensionActionDelegateAndroid(\n    BrowserWindowInterface* browser,\n    const ToolbarActionsModel::ActionId& action_id,\n    extensions::ExtensionsToolbarAndroid* toolbar_android)\n    : browser_(browser),\n      action_id_(action_id),\n      toolbar_android_(toolbar_android) {}\n\nExtensionActionDelegateAndroid::ExtensionActionDelegateAndroid(\n    BrowserWindowInterface* browser,\n    const ToolbarActionsModel::ActionId& action_id,\n    extensions::ExtensionsToolbarAndroid* toolbar_android,\n    const base::android::JavaRef<jobject>& java_menu_object)\n    : browser_(browser),\n      action_id_(action_id),\n      toolbar_android_(toolbar_android),\n      java_menu_object_(java_menu_object) {}|' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|bool ExtensionActionDelegateAndroid::IsShowingPopup\(\) const \{\n  return toolbar_android_->HasActivePopup\(\);\n\}|bool ExtensionActionDelegateAndroid::IsShowingPopup() const {\n  if (!java_menu_object_.is_null()) {\n    return Java_ExtensionsMenuBridge_hasActivePopup(\n        base::android::AttachCurrentThread(), java_menu_object_);\n  }\n  return toolbar_android_->HasActivePopup();\n}|' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|void ExtensionActionDelegateAndroid::HidePopup\(\) \{\n  toolbar_android_->HideActivePopup\(\);\n\}|void ExtensionActionDelegateAndroid::HidePopup() {\n  if (!java_menu_object_.is_null()) {\n    Java_ExtensionsMenuBridge_hideActivePopup(\n        base::android::AttachCurrentThread(), java_menu_object_);\n    return;\n  }\n  toolbar_android_->HideActivePopup();\n}|' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|void ExtensionActionDelegateAndroid::TriggerPopup\(\n    std::unique_ptr<extensions::ExtensionViewHost> host,\n    PopupShowAction show_action,\n    bool by_user,\n    ShowPopupCallback callback\) \{\n  toolbar_android_->TriggerPopup\(action_id_, std::move\(host\)\);\n\}|void ExtensionActionDelegateAndroid::TriggerPopup(\n    std::unique_ptr<extensions::ExtensionViewHost> host,\n    PopupShowAction show_action,\n    bool by_user,\n    ShowPopupCallback callback) {\n  if (!java_menu_object_.is_null()) {\n    Java_ExtensionsMenuBridge_triggerPopup(\n        base::android::AttachCurrentThread(), java_menu_object_, action_id_,\n        reinterpret_cast<int64_t>(host.release()));\n    return;\n  }\n  toolbar_android_->TriggerPopup(action_id_, std::move(host));\n}|' "$ACTION_DELEGATE_CC"
perl -0pi -e 's|void ExtensionActionDelegateAndroid::ShowContextMenuAsFallback\(\) \{\n  toolbar_android_->ShowContextMenu\(action_id_\);\n\}|void ExtensionActionDelegateAndroid::ShowContextMenuAsFallback() {\n  if (!java_menu_object_.is_null()) {\n    Java_ExtensionsMenuBridge_showContextMenu(\n        base::android::AttachCurrentThread(), java_menu_object_, action_id_);\n    return;\n  }\n  toolbar_android_->ShowContextMenu(action_id_);\n}|' "$ACTION_DELEGATE_CC"
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

# ext: priority
sed -i 's|host_contents_->SetColorProviderSource(NoOpColorProviderSource::Get());|&\nhost_contents_->SetPrimaryPageImportance(content::ChildProcessImportance::IMPORTANT, content::ChildProcessImportance::NORMAL);|' extensions/browser/extension_host.cc

# ext: perms prompt
sed -i '/content::WebContents\* web_contents = show_params->GetParentWebContents();/,/DCHECK(view_android);/{/GetParentWebContents/!d}' chrome/browser/ui/android/extensions/extension_install_dialog_view_android.cc
sed -i 's|view_android->GetWindowAndroid();|show_params->GetParentWindow();|' chrome/browser/ui/android/extensions/extension_install_dialog_view_android.cc

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
