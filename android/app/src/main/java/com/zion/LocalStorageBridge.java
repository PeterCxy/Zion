package com.zion;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.util.Map;
import java.util.HashMap;

public class LocalStorageBridge extends ReactContextBaseJavaModule {
    ReactApplicationContext mContext;
    Map<String, LocalStorageImpl> mImpls = new HashMap<>();

    public LocalStorageBridge(ReactApplicationContext context) {
        super(context);
        mContext = context;
    }

    @Override
    public String getName() {
        return "LocalStorageBridge";
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void instantiate(String name) {
        if (!mImpls.containsKey(name)) {
            mImpls.put(name, new LocalStorageImpl(mContext, name));
        }
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String getItem(String name, String key) {
        return mImpls.get(name).getItem(key);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void setItem(String name, String key, String value) {
        mImpls.get(name).setItem(key, value);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void removeItem(String name, String key) {
        mImpls.get(name).removeItem(key);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void key(String name, int index) {
        mImpls.get(name).key(index);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void clear(String name) {
        mImpls.get(name).clear();
    }
}