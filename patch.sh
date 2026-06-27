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
sed -i 's|(view) -> mMenuBridge.executeAction(entry.id))|(view) -> openExtensionFromMenu(entry.id))|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
perl -0pi -e 's|    private void openUrlFromMenu\(String url\) \{\n|    private void openExtensionFromMenu(String extensionId) {\n        mOnDismissMenu.run();\n\n        if (mMenuBridge.openOptionsPage(extensionId)) {\n            return;\n        }\n\n        LoadUrlParams params = new LoadUrlParams(\n                UrlConstants.CHROME_EXTENSIONS_ID_URL + extensionId,\n                PageTransition.AUTO_TOPLEVEL);\n        mTabCreator.createNewTab(params, TabLaunchType.FROM_CHROME_UI, null);\n    }\n\n    private void openUrlFromMenu(String url) {\n|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsMenuMediator.java
perl -0pi -e 's|    /\*\*\n     \* Executes the extension action\.\n     \*\n     \* @param extensionId The ID of the extension to execute\.\n     \*/\n    public void executeAction\(String extensionId\) \{\n        ExtensionsMenuBridgeJni\.get\(\)\n                \.executeAction\(mNativeExtensionsMenuDelegateAndroid, extensionId\);\n    \}\n|    /**\n     * Executes the extension action.\n     *\n     * @param extensionId The ID of the extension to execute.\n     */\n    public void executeAction(String extensionId) {\n        ExtensionsMenuBridgeJni.get()\n                .executeAction(mNativeExtensionsMenuDelegateAndroid, extensionId);\n    }\n\n    /** Opens the extension options page if the extension exposes one. */\n    public boolean openOptionsPage(String extensionId) {\n        return ExtensionsMenuBridgeJni.get()\n                .openOptionsPage(mNativeExtensionsMenuDelegateAndroid, extensionId);\n    }\n|' chrome/browser/ui/android/extensions/java/src/org/chromium/chrome/browser/ui/extensions/ExtensionsMenuBridge.java
perl -0pi -e 's|        /\*\* Executes the extension action\. \*/\n        void executeAction\(\n                long nativeExtensionsMenuDelegateAndroid,\n                @JniType\("std::string"\) String extensionId\);\n|        /** Executes the extension action. */\n        void executeAction(\n                long nativeExtensionsMenuDelegateAndroid,\n                @JniType("std::string") String extensionId);\n\n        /** Opens the extension options page if the extension exposes one. */\n        boolean openOptionsPage(\n                long nativeExtensionsMenuDelegateAndroid,\n                @JniType("std::string") String extensionId);\n|' chrome/browser/ui/android/extensions/java/src/org/chromium/chrome/browser/ui/extensions/ExtensionsMenuBridge.java
sed -i '/void ExecuteAction(JNIEnv\* env, const extensions::ExtensionId& extension_id);/a\  bool OpenOptionsPage(JNIEnv* env, const extensions::ExtensionId& extension_id);' chrome/browser/ui/android/extensions/extensions_menu_delegate_android.h
sed -i '/#include "chrome\/browser\/ui\/android\/extensions\/extension_action_delegate_android.h"/a\#include "chrome/browser/extensions/extension_tab_util.h"\n#include "extensions/browser/extension_registry.h"' chrome/browser/ui/android/extensions/extensions_menu_delegate_android.cc
perl -0pi -e 's|void ExtensionsMenuDelegateAndroid::ExecuteAction\(\n    JNIEnv\* env,\n    const extensions::ExtensionId& extension_id\) \{\n  menu_model_->ExecuteAction\(extension_id\);\n\}\n|void ExtensionsMenuDelegateAndroid::ExecuteAction(\n    JNIEnv* env,\n    const extensions::ExtensionId& extension_id) {\n  menu_model_->ExecuteAction(extension_id);\n}\n\nbool ExtensionsMenuDelegateAndroid::OpenOptionsPage(\n    JNIEnv* env,\n    const extensions::ExtensionId& extension_id) {\n  const extensions::Extension* extension =\n      extensions::ExtensionRegistry::Get(browser_->GetProfile())\n          ->enabled_extensions()\n          .GetByID(extension_id);\n  if (!extension) {\n    return false;\n  }\n\n  return extensions::ExtensionTabUtil::OpenOptionsPage(extension, browser_);\n}\n|' chrome/browser/ui/android/extensions/extensions_menu_delegate_android.cc

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
sed -i '/info.in_developer_mode =/,/prefs::kExtensionsUIDeveloperMode);/c\  info.in_developer_mode = true;' chrome/browser/extensions/api/developer_private/profile_info_generator.cc
sed -i '/info.can_load_unpacked =/,/->HasAllowlistedExtension();/c\  info.can_load_unpacked = true;' chrome/browser/extensions/api/developer_private/profile_info_generator.cc
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

# ext: mv2
sed -i 's/BASE_FEATURE(kExtensionManifestV2Unsupported, base::FEATURE_ENABLED_BY_DEFAULT);/BASE_FEATURE(kExtensionManifestV2Unsupported, base::FEATURE_DISABLED_BY_DEFAULT);/' extensions/common/extension_features.cc
sed -i 's/BASE_FEATURE(kExtensionManifestV2Disabled, base::FEATURE_ENABLED_BY_DEFAULT);/BASE_FEATURE(kExtensionManifestV2Disabled, base::FEATURE_DISABLED_BY_DEFAULT);/' extensions/common/extension_features.cc
perl -0pi -e 's|bool ExtensionManagement::IsAllowedByUnpackedDeveloperModePolicy\(\n    const Extension& extension\) \{\n.*?\n\}\n\nbool ExtensionManagement::IsGreylistedForceInstalledInLowTrustEnvironment|bool ExtensionManagement::IsAllowedByUnpackedDeveloperModePolicy(\n    const Extension& extension) {\n  return true;\n}\n\nbool ExtensionManagement::IsGreylistedForceInstalledInLowTrustEnvironment|s' chrome/browser/extensions/extension_management.cc
sed -i 's|return IsFromStore(extension, context) && CanUseExtensionApis(extension);|return extension.from_webstore() \&\& CanUseExtensionApis(extension);|' extensions/browser/install_verifier.cc
perl -0pi -e 's|  if \(AllowedByEnterprisePolicy\(extension->id\(\)\) &&\n      !ExtensionsBrowserClient::Get\(\)\n           ->GetExtensionManagementClient\(context_\)\n           ->IsForceInstalledInLowTrustEnvironment\(\*extension\)\) \{\n    return false;\n  \}\n\n  bool verified = true;|  if (AllowedByEnterprisePolicy(extension->id()) &&\n      !ExtensionsBrowserClient::Get()\n           ->GetExtensionManagementClient(context_)\n           ->IsForceInstalledInLowTrustEnvironment(*extension)) {\n    return false;\n  }\n  if (!extension->from_webstore()) {\n    return false;\n  }\n\n  bool verified = true;|' extensions/browser/install_verifier.cc
perl -0pi -e 's/^\s+"proxy\.json",\n//mg; s/^(schema_sources_ = \[\n)/$1  "proxy.json",\n/' chrome/common/extensions/api/api_sources.gni
perl -0pi -e 's/^\s+"browser_action\.json",\n//mg; s/^\s+"page_action\.json",\n//mg; s/^(uncompiled_sources_ = \[\n)/$1  "browser_action.json",\n  "page_action.json",\n/' chrome/common/extensions/api/api_sources.gni
sed -i 's/api::webstore_private::MV2DeprecationStatus::kHardDisable)));/api::webstore_private::MV2DeprecationStatus::kNone)));/' chrome/browser/extensions/api/webstore_private/webstore_private_api.cc
sed -i 's/bool g_allow_mv2_for_testing = false;/bool g_allow_mv2_for_testing = true;/' extensions/browser/manifest_v2_experiment_manager.cc

# android: require explicit user confirmation before launching external apps
perl -0pi -e 's|            if \(debug\(\)\) Log\.i\(TAG, "startActivity"\);\n            context\.startActivity\(intent\);\n            recordExternalNavigationDispatched\(intent\);\n            mDelegate\.reportIntentToSafeBrowsing\(intent\);|            if (debug()) Log.i(TAG, "startActivity");\n            Intent launchIntent = intent;\n            if (!Intent.ACTION_CHOOSER.equals(intent.getAction())\n                    \&\& !Intent.ACTION_PICK_ACTIVITY.equals(intent.getAction())) {\n                launchIntent = Intent.createChooser(intent, null);\n            }\n            context.startActivity(launchIntent);\n            recordExternalNavigationDispatched(intent);\n            mDelegate.reportIntentToSafeBrowsing(intent);|' components/external_intents/android/java/src/org/chromium/components/external_intents/ExternalNavigationHandler.java

# ext: isolate top-level navigations from extension blockers
sed -i '/case DNRRequestAction::Type::BLOCK:/,/case DNRRequestAction::Type::ALLOW:/ s|ClearPendingCallbacks(browser_context, \*request);|if (request->web_request_type == WebRequestResourceType::MAIN_FRAME) { break; }\n          ClearPendingCallbacks(browser_context, *request);|' extensions/browser/api/web_request/extension_web_request_event_router.cc
sed -i '/case DNRRequestAction::Type::REDIRECT:/,/case DNRRequestAction::Type::MODIFY_HEADERS:/ s|ClearPendingCallbacks(browser_context, \*request);|if (request->web_request_type == WebRequestResourceType::MAIN_FRAME) { break; }\n          ClearPendingCallbacks(browser_context, *request);|' extensions/browser/api/web_request/extension_web_request_event_router.cc
sed -i '/  const bool redirected =/i\
  if (request->web_request_type == WebRequestResourceType::MAIN_FRAME) {\
    canceled_by_extension.reset();\
    if (blocked_request.new_url \&\& !blocked_request.new_url->is_empty() \&\&\
        !blocked_request.new_url->SchemeIs("chrome-extension")) {\
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
sed -i '/Pref.PIN_EXTENSIONS_MENU_BUTTON, this::updateMenuButtonPinState);$/a\if (mPrefService.getBoolean(Pref.PIN_EXTENSIONS_MENU_BUTTON)) { mContainer.findViewById(R.id.extensions_menu_button).setVisibility(View.VISIBLE); } else { mContainer.findViewById(R.id.extensions_menu_button).setVisibility(View.GONE); }' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
sed -i '/"ExtensionsToolbarCoordinatorImpl.requestLayoutWithViewUtils()");$/a\mContainer.findViewById(R.id.extensions_menu_button).setVisibility(isMenuButtonPinned() ? View.VISIBLE : View.GONE);' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java

# ext: incognito

# ext: priority
sed -i 's|host_contents_->SetColorProviderSource(NoOpColorProviderSource::Get());|&\nhost_contents_->SetPrimaryPageImportance(content::ChildProcessImportance::IMPORTANT, content::ChildProcessImportance::NORMAL);|' extensions/browser/extension_host.cc

# ext: perms prompt
sed -i '/content::WebContents\* web_contents = show_params->GetParentWebContents();/,/DCHECK(view_android);/{/GetParentWebContents/!d}' chrome/browser/ui/android/extensions/extension_install_dialog_view_android.cc
sed -i 's|view_android->GetWindowAndroid();|show_params->GetParentWindow();|' chrome/browser/ui/android/extensions/extension_install_dialog_view_android.cc

# tmp
sed -i 's/BASE_FEATURE(kAndroidSearchInSettings,"SearchInSettings", base::FEATURE_DISABLED_BY_DEFAULT);/BASE_FEATURE(kAndroidSearchInSettings,"SearchInSettings", base::FEATURE_ENABLED_BY_DEFAULT);/' chrome/browser/flags/android/chrome_feature_list.cc
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

# crbug.com/helium: startup blank-screen recovery guards
sed -i '/import org.chromium.components.embedder_support.util.UrlUtilities;/i\
import org.chromium.components.embedder_support.util.UrlConstants;' chrome/android/java/src/org/chromium/chrome/browser/tabmodel/TabPersistentStoreImpl.java
sed -i '/private static boolean sDeferredStartupComplete;/a\
\
    private static boolean shouldReplaceUrlForRestore(@Nullable String url) {\
        return TextUtils.isEmpty(url);\
    }\
\
    private static String safeUrlForRestore(@Nullable String url) {\
        return shouldReplaceUrlForRestore(url) ? UrlConstants.VERSION_URL : assumeNonNull(url);\
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
perl -0pi -e 's|    \@Override\n    public void onStartWithNative\(\) \{|    private void clearVolatileRendererCaches() {\n        PostTask.postTask(\n                TaskTraits.BEST_EFFORT_MAY_BLOCK,\n                () -> {\n                    String dataDir = org.chromium.base.PathUtils.getDataDirectory();\n                    String[] paths = {\n                        "Default/GPUCache",\n                        "Default/GrShaderCache",\n                        "Default/ShaderCache",\n                        "Default/Code Cache/js",\n                        "Default/Code Cache/wasm"\n                    };\n                    for (String path : paths) {\n                        org.chromium.base.FileUtils.recursivelyDeleteFile(\n                                new java.io.File(dataDir, path),\n                                org.chromium.base.FileUtils.DELETE_ALL);\n                    }\n                });\n    }\n\n    \@Override\n    public void onStartWithNative() {|' chrome/android/java/src/org/chromium/chrome/browser/ChromeTabbedActivity.java
sed -i '/super.onStartWithNative();/a\
        clearVolatileRendererCaches();' chrome/android/java/src/org/chromium/chrome/browser/ChromeTabbedActivity.java

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
