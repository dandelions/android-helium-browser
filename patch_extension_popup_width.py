#!/usr/bin/env python3

from pathlib import Path
import sys


if len(sys.argv) != 5:
    raise SystemExit(
        "usage: patch_extension_popup_width.py POPUP_JAVA CONTENTS_JAVA "
        "CONTENTS_CC CONTENTS_H"
    )


def replace_if_missing(path, text, marker, old, new):
    if marker in text:
        return text
    if old not in text:
        raise SystemExit(f"Extension popup width pattern not found in {path}: {marker}")
    return text.replace(old, new, 1)


popup = Path(sys.argv[1])
java_contents = Path(sys.argv[2])
native_contents = Path(sys.argv[3])
native_header = Path(sys.argv[4])

popup_text = popup.read_text()
popup_text = replace_if_missing(
    popup,
    popup_text,
    "private static final int POPUP_EDGE_MARGIN_DP = 8;",
    "class ExtensionActionPopup implements Destroyable {\n",
    "class ExtensionActionPopup implements Destroyable {\n"
    "    private static final int POPUP_EDGE_MARGIN_DP = 8;\n",
)
popup_text = replace_if_missing(
    popup,
    popup_text,
    "mContents.setMaxWidth(maxContentWidthDp);",
    "        Resources resources = mActivity.getResources();\n"
    "        mPopupWindow.setElevation(\n",
    "        Resources resources = mActivity.getResources();\n"
    "        int popupMarginPx = ViewUtils.dpToPx(mActivity, POPUP_EDGE_MARGIN_DP);\n"
    "        View rootView = mActivity.getWindow().getDecorView();\n"
    "        int rootViewWidthPx = rootView.getWidth();\n"
    "        if (rootViewWidthPx <= 0) {\n"
    "            rootViewWidthPx = resources.getDisplayMetrics().widthPixels;\n"
    "        }\n"
    "        int maxContentWidthPx = Math.max(rootViewWidthPx - 2 * popupMarginPx, 1);\n"
    "        int maxContentWidthDp =\n"
    "                Math.max(\n"
    "                        (int)\n"
    "                                (maxContentWidthPx\n"
    "                                        / resources.getDisplayMetrics().density),\n"
    "                        1);\n"
    "        mContents.setMaxWidth(maxContentWidthDp);\n"
    "        mPopupWindow.setMargin(popupMarginPx);\n"
    "        mPopupWindow.setElevation(\n",
)
java_text = java_contents.read_text()
java_text = replace_if_missing(
    java_contents,
    java_text,
    "public void setMaxWidth(int maxWidth)",
    "    /**\n"
    "     * Instructs to load the initial page for the extension popup into its {@link WebContents}.\n",
    "    /** Sets the maximum popup content width in device-independent pixels. */\n"
    "    public void setMaxWidth(int maxWidth) {\n"
    "        assert mNativeExtensionActionPopupContents != 0;\n"
    "        ExtensionActionPopupContentsJni.get()\n"
    "                .setMaxWidth(mNativeExtensionActionPopupContents, maxWidth);\n"
    "    }\n\n"
    "    /**\n"
    "     * Instructs to load the initial page for the extension popup into its {@link WebContents}.\n",
)
java_text = replace_if_missing(
    java_contents,
    java_text,
    "long nativeExtensionActionPopupContents, int maxWidth);",
    "        /**\n"
    "         * Triggers the loading of the initial URL in the native ExtensionActionPopupContents.\n",
    "        /** Sets the maximum content width in device-independent pixels. */\n"
    "        void setMaxWidth(\n"
    "                long nativeExtensionActionPopupContents, int maxWidth);\n\n"
    "        /**\n"
    "         * Triggers the loading of the initial URL in the native ExtensionActionPopupContents.\n",
)

header_text = native_header.read_text()
header_text = replace_if_missing(
    native_header,
    header_text,
    "void SetMaxWidth(JNIEnv* env, int max_width);",
    "  void LoadInitialPage(JNIEnv* env);\n",
    "  void LoadInitialPage(JNIEnv* env);\n\n"
    "  void SetMaxWidth(JNIEnv* env, int max_width);\n",
)
header_text = replace_if_missing(
    native_header,
    header_text,
    "int max_width_ = 800;",
    "  std::unique_ptr<ExtensionViewHost> host_;\n",
    "  std::unique_ptr<ExtensionViewHost> host_;\n"
    "  // Maximum content width in CSS/device-independent pixels.\n"
    "  int max_width_ = 800;\n",
)
native_text = native_contents.read_text()
if "#include <algorithm>" not in native_text:
    anchor = '#include "chrome/browser/ui/android/extensions/extension_action_popup_contents.h"\n'
    if anchor not in native_text:
        raise SystemExit(f"Extension popup include anchor not found in {native_contents}")
    native_text = native_text.replace(anchor, anchor + "\n#include <algorithm>\n", 1)
native_text = native_text.replace(
    "constexpr gfx::Size kMinSize = {25, 25};",
    "constexpr gfx::Size kMinSize = {256, 25};",
    1,
)
native_text = replace_if_missing(
    native_contents,
    native_text,
    "void ExtensionActionPopupContents::SetMaxWidth(",
    "void ExtensionActionPopupContents::LoadInitialPage(JNIEnv* env) {\n"
    "  host_->CreateRendererSoon();\n"
    "}\n",
    "void ExtensionActionPopupContents::LoadInitialPage(JNIEnv* env) {\n"
    "  host_->CreateRendererSoon();\n"
    "}\n\n"
    "void ExtensionActionPopupContents::SetMaxWidth(JNIEnv* env, int max_width) {\n"
    "  max_width_ = std::clamp(max_width, 1, kMaxSize.width());\n"
    "  RenderFrameHost* main_frame =\n"
    "      host_->host_contents()->GetPrimaryMainFrame();\n"
    "  if (main_frame->IsRenderFrameLive()) {\n"
    "    SetUpNewMainFrame(main_frame);\n"
    "  }\n"
    "}\n",
)
native_text = replace_if_missing(
    native_contents,
    native_text,
    "EnableAutoResize(min_size, max_size);",
    "  render_frame_host->GetView()->EnableAutoResize(kMinSize, kMaxSize);\n",
    "  const gfx::Size max_size(max_width_, kMaxSize.height());\n"
    "  const gfx::Size min_size(std::min(kMinSize.width(), max_width_),\n"
    "                           kMinSize.height());\n"
    "  render_frame_host->GetView()->EnableAutoResize(min_size, max_size);\n",
)
required = (
    "constexpr gfx::Size kMinSize = {256, 25};",
    "void ExtensionActionPopupContents::SetMaxWidth(",
    "EnableAutoResize(min_size, max_size);",
)
for marker in required:
    if marker not in native_text:
        raise SystemExit(f"Extension popup width marker missing in {native_contents}: {marker}")

popup.write_text(popup_text)
java_contents.write_text(java_text)
native_contents.write_text(native_text)
native_header.write_text(header_text)
