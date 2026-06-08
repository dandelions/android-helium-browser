#!/bin/bash

mkdir -p chrome/android/java/res_helium_base
for icon in $(find chrome/android/java/res_helium_base -type f -name '*.png'); do convert $icon -fill navy -tint 36 $icon; done

sed -i '/feature_overrides.EnableFeature(::features::kSkipVulkanBlocklist);/d' chrome/browser/chrome_browser_field_trials.cc
sed -i '/feature_overrides.EnableFeature(::features::kDefaultANGLEVulkan);/d' chrome/browser/chrome_browser_field_trials.cc
sed -i '/feature_overrides.EnableFeature(::features::kVulkanFromANGLE);/d' chrome/browser/chrome_browser_field_trials.cc
sed -i '/feature_overrides.EnableFeature(::features::kDefaultPassthroughCommandDecoder);/d' chrome/browser/chrome_browser_field_trials.cc

# dev
sed -i 's/BASE_FEATURE(kSubmenusInAppMenu, base::FEATURE_DISABLED_BY_DEFAULT);/BASE_FEATURE(kSubmenusInAppMenu, base::FEATURE_ENABLED_BY_DEFAULT);/' chrome/browser/flags/android/chrome_feature_list.cc
sed -i '/BASE_FEATURE(kTaskManagerClank,/,/);/ s/base::FEATURE_DISABLED_BY_DEFAULT/base::FEATURE_ENABLED_BY_DEFAULT/' chrome/browser/task_manager/common/task_manager_features.cc
sed -i 's/BASE_FEATURE(kAndroidDevToolsFrontend, base::FEATURE_DISABLED_BY_DEFAULT);/BASE_FEATURE(kAndroidDevToolsFrontend, base::FEATURE_ENABLED_BY_DEFAULT);/' content/public/common/content_features.cc
sed -i 's|if (!DeviceFormFactor.isNonMultiDisplayContextOnTablet(mContext)) {|if (false) {|' chrome/android/java/src/org/chromium/chrome/browser/tabbed_mode/TabbedAppMenuPropertiesDelegate.java

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
sed -i 's|uncompiled_sources_ = \[|&\n  "browser_action.json",\n  "page_action.json",|' chrome/common/extensions/api/api_sources.gni
sed -i 's/api::webstore_private::MV2DeprecationStatus::kHardDisable)));/api::webstore_private::MV2DeprecationStatus::kNone)));/' chrome/browser/extensions/api/webstore_private/webstore_private_api.cc
sed -i 's/bool g_allow_mv2_for_testing = false;/bool g_allow_mv2_for_testing = true;/' extensions/browser/manifest_v2_experiment_manager.cc

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
sed -i '/Pref.PIN_EXTENSIONS_MENU_BUTTON, this::updateMenuButtonPinState);$/a\if (!mPrefService.getBoolean(Pref.PIN_EXTENSIONS_MENU_BUTTON)) { mContainer.findViewById(R.id.extensions_menu_button).setVisibility(View.GONE); }' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
sed -i '/"ExtensionsToolbarCoordinatorImpl.requestLayoutWithViewUtils()");$/a\if (!isMenuButtonPinned()) { mContainer.findViewById(R.id.extensions_menu_button).setVisibility(View.GONE); }' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java

# ext: incognito
sed -i 's|if (!context->IsOffTheRecord()) {|if (true) {|' extensions/browser/process_manager.cc
sed -i 's|public static boolean shouldOpenIncognitoAsWindow() {|public static boolean shouldOpenIncognitoAsWindow() { if (true) return true;|' chrome/browser/incognito/android/java/src/org/chromium/chrome/browser/incognito/IncognitoUtils.java

# tmp
sed -i 's|if (!IncognitoUtils.shouldOpenIncognitoAsWindow() \|\| isIncognitoShowing()) {|if (true) {|' chrome/android/java/src/org/chromium/chrome/browser/tabbed_mode/TabbedAppMenuPropertiesDelegate.java
sed -i 's/BASE_FEATURE(kAndroidSearchInSettings,"SearchInSettings", base::FEATURE_DISABLED_BY_DEFAULT);/BASE_FEATURE(kAndroidSearchInSettings,"SearchInSettings", base::FEATURE_ENABLED_BY_DEFAULT);/' chrome/browser/flags/android/chrome_feature_list.cc
for file in components/omnibox/browser/autocomplete_match.h components/omnibox/browser/autocomplete_match.cc components/omnibox/browser/actions/omnibox_action.h components/omnibox/browser/location_bar_model_impl.cc components/omnibox/browser/location_bar_model_util.cc; do
sed -i '/#include "build\/build_config.h"/i #include "build/android_buildflags.h"' $file
sed -i 's/#if (!BUILDFLAG(IS_ANDROID) || BUILDFLAG(ENABLE_VR)) && !BUILDFLAG(IS_IOS)/#if (!BUILDFLAG(IS_ANDROID) || BUILDFLAG(ENABLE_VR) || BUILDFLAG(IS_DESKTOP_ANDROID)) \&\& !BUILDFLAG(IS_IOS)/' $file
done

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
