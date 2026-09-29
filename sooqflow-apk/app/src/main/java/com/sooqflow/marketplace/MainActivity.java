package com.sooqflow.marketplace;

import android.app.Activity;
import android.app.KeyguardManager;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
    private static final int ADMIN_AUTH_REQUEST = 4107;
    private WebView web;
    private String pendingAdminAction = "";

    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        web = new WebView(this);
        setContentView(web);

        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        s.setAllowContentAccess(false);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        if (android.os.Build.VERSION.SDK_INT >= 26) s.setSafeBrowsingEnabled(true);

        web.addJavascriptInterface(new AndroidSecurityBridge(), "AndroidSecurity");
        web.setWebViewClient(new WebViewClient());
        web.loadUrl("file:///android_asset/index.html");
    }

    public class AndroidSecurityBridge {
        @JavascriptInterface
        public void requestCredentialCheck(final String action) {
            runOnUiThread(() -> {
                pendingAdminAction = action == null ? "" : action;
                KeyguardManager km = (KeyguardManager) getSystemService(Context.KEYGUARD_SERVICE);
                if (km == null || !km.isDeviceSecure()) {
                    sendAdminAuthResult(false, pendingAdminAction);
                    return;
                }
                Intent intent = km.createConfirmDeviceCredentialIntent(
                        "SooqFlow Administrator",
                        "Confirm your Android PIN, pattern, or password to continue."
                );
                if (intent == null) {
                    sendAdminAuthResult(false, pendingAdminAction);
                    return;
                }
                startActivityForResult(intent, ADMIN_AUTH_REQUEST);
            });
        }
    }

    @Override protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == ADMIN_AUTH_REQUEST) {
            boolean ok = resultCode == RESULT_OK;
            sendAdminAuthResult(ok, pendingAdminAction);
            pendingAdminAction = "";
        }
    }

    private void sendAdminAuthResult(boolean ok, String action) {
        if (web == null) return;
        final String safeAction = action == null ? "" : action.replace("\\", "").replace("'", "");
        final String js = "window.onAdminDeviceAuth(" + (ok ? "true" : "false") + ",'" + safeAction + "')";
        web.post(() -> web.evaluateJavascript(js, null));
    }

    @Override public void onBackPressed() {
        if (web != null && web.canGoBack()) web.goBack();
        else super.onBackPressed();
    }

    @Override protected void onDestroy() {
        if (web != null) {
            web.removeJavascriptInterface("AndroidSecurity");
            web.loadUrl("about:blank");
            web.stopLoading();
            web.removeAllViews();
            web.destroy();
            web = null;
        }
        super.onDestroy();
    }
}