package com.zion;

import android.app.Activity;
import android.view.WindowManager;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.util.Map;
import java.util.HashMap;

public class SoftInputMode extends ReactContextBaseJavaModule {
    public SoftInputMode(ReactApplicationContext context) {
        super(context);
    }

    @Override
    public String getName() {
        return "SoftInputMode";
    }

    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        constants.put("ADJUST_RESIZE", WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
        constants.put("ADJUST_PAN", WindowManager.LayoutParams.SOFT_INPUT_ADJUST_PAN);
        return constants;
    }

    @ReactMethod
    public void setSoftInputMode(int mode) {
        final Activity activity = getCurrentActivity();

        if (activity != null) {
            activity.runOnUiThread(() -> {
                activity.getWindow().setSoftInputMode(mode);
            });
        }
    }
}