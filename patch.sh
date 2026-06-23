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

# search
sed -i 's|BASE_FEATURE(kOmniboxSiteSearch, DISABLED);|BASE_FEATURE(kOmniboxSiteSearch, ENABLED);|' components/omnibox/common/omnibox_features.cc

# playback
sed -i 's|#if BUILDFLAG(IS_ANDROID)|#if 0|' content/public/renderer/render_frame_media_playback_options.cc

# viewport
sed -i 's|constexpr gfx::Size kMinSize = {25, 25};|constexpr gfx::Size kMinSize = {256, 25};|' chrome/browser/ui/android/extensions/extension_action_popup_contents.cc
sed -i 's|<meta name="color-scheme" content="light dark">|&\n<meta name="viewport" content="width=device-width">|' chrome/browser/resources/extensions/extensions.html
sed -i 's|--extensions-card-width: 400px;|--extensions-card-width: 96%;|' chrome/browser/resources/extensions/item_list.css # card width
sed -i 's|--cr-toolbar-field-width: 680px;|--cr-toolbar-field-width: 96%;|' chrome/browser/resources/extensions/shared_vars.css # page content
sed -i 's|padding: 24px 60px 64px;|padding: 24px 0 64px;|' chrome/browser/resources/extensions/item_list.css # content wrapper

# ext: mv2
sed -i 's/BASE_FEATURE(kExtensionManifestV2Unsupported, base::FEATURE_ENABLED_BY_DEFAULT);/BASE_FEATURE(kExtensionManifestV2Unsupported, base::FEATURE_DISABLED_BY_DEFAULT);/' extensions/common/extension_features.cc
sed -i 's/BASE_FEATURE(kExtensionManifestV2Disabled, base::FEATURE_ENABLED_BY_DEFAULT);/BASE_FEATURE(kExtensionManifestV2Disabled, base::FEATURE_DISABLED_BY_DEFAULT);/' extensions/common/extension_features.cc
sed -i 's|^schema_sources_ = \[|&\n  "proxy.json",|' chrome/common/extensions/api/api_sources.gni
sed -i 's|uncompiled_sources_ = \[|&\n  "browser_action.json",\n  "page_action.json",|' chrome/common/extensions/api/api_sources.gni
sed -i 's/api::webstore_private::MV2DeprecationStatus::kHardDisable)));/api::webstore_private::MV2DeprecationStatus::kNone)));/' chrome/browser/extensions/api/webstore_private/webstore_private_api.cc
sed -i 's/bool g_allow_mv2_for_testing = false;/bool g_allow_mv2_for_testing = true;/' extensions/browser/manifest_v2_experiment_manager.cc

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
sed -i '/  bool inject_css = !script->css_scripts().empty() &&/,/      !script->js_scripts().empty() && script->run_location() == run_location;/c\
  // Delay extension document_start work in the outermost page until\
  // DOMContentLoaded. Dark-mode/style extensions can otherwise alter CSS or\
  // script state before the page initializes, leaving some sites blank. Keep\
  // extension pages at their declared timing so new-tab/homepage extensions\
  // such as iTabs can initialize normally.\
  const bool delay_main_frame_document_start =\
      host_id_.type == mojom::HostID::HostType::kExtensions &&\
      web_frame->IsOutermostMainFrame() &&\
      !document_url.SchemeIs("chrome-extension");\
\
  mojom::RunLocation script_run_location = script->run_location();\
  if (delay_main_frame_document_start &&\
      script_run_location == mojom::RunLocation::kDocumentStart) {\
    script_run_location = mojom::RunLocation::kDocumentEnd;\
  }\
\
  const mojom::RunLocation css_run_location =\
      delay_main_frame_document_start ? mojom::RunLocation::kDocumentEnd\
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

# ext: hub button
sed -i '/mContainer = (LinearLayout) extensionsToolbarStub.inflate();/a\
        mContainer.findViewById(R.id.extension_action_list).setVisibility(View.GONE);\
        mContainer.findViewById(R.id.extensions_request_access_button).setVisibility(View.GONE);\
        mContainer.findViewById(R.id.extensions_menu_button).setVisibility(View.VISIBLE);' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
sed -i 's/return mPrefService.getBoolean(Pref.PIN_EXTENSIONS_MENU_BUTTON);/return true;/' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
sed -i '/int visibility = shouldShowMenuIcon() ? View.VISIBLE : View.GONE;/c\        int visibility = View.VISIBLE;' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
sed -i '/android:id="@+id\/extensions_menu_pin_menu_icon_button"/a\        android:visibility="gone"' chrome/browser/ui/android/extensions/java/res/layout/extensions_menu_footer.xml
sed -i '/return mExtensionActionListCoordinator.hasPoppedOutAction();/c\            return false;' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
sed -i '/return mToolbarModel.get(ExtensionsToolbarProperties.IS_REQUEST_ACCESS_BUTTON_VISIBLE);/c\            return false;' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
sed -i '/return mContainer.findViewById(R.id.extension_action_list).getVisibility()/,+1c\            return false;' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
sed -i '/return mExtensionActionListCoordinator.fitActionsWithinWidth(availableWidth);/c\
            mContainer.findViewById(R.id.extension_action_list).setVisibility(View.GONE);\
            return 0;' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java

# ext: incognito
sed -i 's|if (!context->IsOffTheRecord()) {|if (true) {|' extensions/browser/process_manager.cc
sed -i 's|public static boolean shouldOpenIncognitoAsWindow() {|public static boolean shouldOpenIncognitoAsWindow() { if (true) return true;|' chrome/browser/incognito/android/java/src/org/chromium/chrome/browser/incognito/IncognitoUtils.java

# ext: priority
sed -i 's|host_contents_->SetColorProviderSource(NoOpColorProviderSource::Get());|&\nhost_contents_->SetPrimaryPageImportance(content::ChildProcessImportance::IMPORTANT, content::ChildProcessImportance::NORMAL);|' extensions/browser/extension_host.cc

# ext: perms prompt
sed -i '/content::WebContents\* web_contents = show_params->GetParentWebContents();/,/DCHECK(view_android);/{/GetParentWebContents/!d}' chrome/browser/ui/android/extensions/extension_install_dialog_view_android.cc
sed -i 's|view_android->GetWindowAndroid();|show_params->GetParentWindow();|' chrome/browser/ui/android/extensions/extension_install_dialog_view_android.cc

# tmp
sed -i 's|if (!IncognitoUtils.shouldOpenIncognitoAsWindow() \|\| isIncognitoShowing()) {|if (true) {|' chrome/android/java/src/org/chromium/chrome/browser/tabbed_mode/TabbedAppMenuPropertiesDelegate.java
sed -i 's/BASE_FEATURE(kAndroidSearchInSettings,"SearchInSettings", base::FEATURE_DISABLED_BY_DEFAULT);/BASE_FEATURE(kAndroidSearchInSettings,"SearchInSettings", base::FEATURE_ENABLED_BY_DEFAULT);/' chrome/browser/flags/android/chrome_feature_list.cc
for file in components/omnibox/browser/autocomplete_match.h components/omnibox/browser/autocomplete_match.cc components/omnibox/browser/actions/omnibox_action.h components/omnibox/browser/location_bar_model_impl.cc components/omnibox/browser/location_bar_model_util.cc; do
sed -i '/#include "build\/build_config.h"/i #include "build/android_buildflags.h"' $file
sed -i 's/#if (!BUILDFLAG(IS_ANDROID) || BUILDFLAG(ENABLE_VR)) && !BUILDFLAG(IS_IOS)/#if (!BUILDFLAG(IS_ANDROID) || BUILDFLAG(ENABLE_VR) || BUILDFLAG(IS_DESKTOP_ANDROID)) \&\& !BUILDFLAG(IS_IOS)/' $file
done
sed -i 's/if ((!is_android || enable_vr) && !is_ios) {/if ((!is_android || enable_vr || is_desktop_android) \&\& !is_ios) {/' components/omnibox/browser/BUILD.gn

# crbug.com/40831291: bottom address bar
sed -i 's@(idealFitsBelow && spaceBelowAnchor >= spaceAboveAnchor) || !idealFitsAbove;@(idealFitsBelow == idealFitsAbove) ? (spaceBelowAnchor >= spaceAboveAnchor) : idealFitsBelow;@' ui/android/java/src/org/chromium/ui/widget/PopupSpecCalculator.java

# crbug.com/404069963: ntp override
sed -i 's|newCachedFlag(CHROME_NATIVE_URL_OVERRIDING, BuildConfig.IS_DESKTOP_ANDROID)|newCachedFlag(CHROME_NATIVE_URL_OVERRIDING, true)|' chrome/browser/flags/android/java/src/org/chromium/chrome/browser/flags/ChromeFeatureList.java

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
