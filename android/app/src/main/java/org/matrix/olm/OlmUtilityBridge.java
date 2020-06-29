package org.matrix.olm;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

// The OlmUtility object contains no internal state
// so here we model it as a basically static class
// (on the JS side)
public class OlmUtilityBridge extends ReactContextBaseJavaModule {
    private OlmUtility mUtil;

    public OlmUtilityBridge(ReactApplicationContext context) {
        super(context);

        try {
            mUtil = new OlmUtility();
        } catch (OlmException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public String getName() {
        return "OlmUtilityBridge";
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String sha256(String input) throws OlmException {
        return mUtil.sha256(input);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public boolean ed25519verify(String key, String message, String signature) {
        try {
            mUtil.verifyEd25519Signature(signature, key, message);
            return true;
        } catch (OlmException e) {
            return false;
        }
    }
}