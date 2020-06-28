package com.zion;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.ArrayMap;

import java.util.Map;

// An implementation of a LocalStorage-like API
class LocalStorageImpl {
    // Use ArrayMap because we need methods like key(n)
    private ArrayMap<String, String> mMemCache = new ArrayMap<>();
    private SharedPreferences mPrefs;

    public LocalStorageImpl(Context context, String name) {
        mPrefs = context.getSharedPreferences(name, Context.MODE_PRIVATE);
        Map<String, ?> records = mPrefs.getAll();
        for (Map.Entry<String, ?> entry : records.entrySet()) {
            mMemCache.put(entry.getKey(), (String) entry.getValue()); // We only store Strings
        }
    }

    public String getItem(String key) {
        return mMemCache.get(key);
    }

    public void setItem(String key, String value) {
        mPrefs.edit().putString(key, value).apply();
        mMemCache.put(key, value);
    }

    public void removeItem(String key) {
        mPrefs.edit().remove(key).apply();
        mMemCache.remove(key);
    }

    public String key(int index) {
        return mMemCache.keyAt(index);
    }

    public void clear() {
        mPrefs.edit().clear().apply();
        mMemCache.clear();
    }

    public int getLength() {
        return mMemCache.size();
    }
}