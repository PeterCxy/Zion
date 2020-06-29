package org.matrix.olm;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class OlmManagerBridge extends ReactContextBaseJavaModule {
    private OlmManager mManager = new OlmManager();

    public OlmManagerBridge(ReactApplicationContext context) {
        super(context);
    }

    @Override
    public String getName() {
        return "OlmManagerBridge";
    }

    // Format: "X.X.X", remember the JS side expects an array
    @ReactMethod(isBlockingSynchronousMethod = true)
    public String getLibraryVersion() {
        return mManager.getOlmLibVersion();
    }
}