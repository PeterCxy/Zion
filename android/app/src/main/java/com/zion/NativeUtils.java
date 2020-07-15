package com.zion;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import androidx.core.content.FileProvider;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;

import java.io.File;

public class NativeUtils extends ReactContextBaseJavaModule {
    private Context mContext;

    public NativeUtils(ReactApplicationContext context) {
        super(context);
        mContext = context;
    }

    @Override
    public String getName() {
        return "NativeUtils";
    }

    @ReactMethod
    public void openURL(String url) {
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        mContext.startActivity(intent);
    }

    // Open a file in internal cache path (FS_CACHE_PATH) in other applications
    @ReactMethod
    public void openFile(String path) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setData(
            FileProvider.getUriForFile(mContext,
                "im.angry.zion.fileprovider", new File(path)));
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        mContext.startActivity(intent);
    }

    // Save a file to external storage, asking user to choose the destination
    @ReactMethod
    public void saveFileToExternal(String path, String name, String mime, Promise promise) {
        final Activity activity = getCurrentActivity();

        if (activity != null && activity instanceof MainActivity) {
            ((MainActivity) activity).saveFileToExternal(path, name, mime, promise);
        } else {
            promise.reject("No activity found");
        }
    }
}