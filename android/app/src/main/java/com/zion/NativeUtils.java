package com.zion;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

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
}