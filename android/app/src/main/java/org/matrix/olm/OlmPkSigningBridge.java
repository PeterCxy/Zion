package org.matrix.olm;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.util.Base64;

public class OlmPkSigningBridge extends OlmBridgeBase<OlmPkSigning> {
    private static OlmPkSigningBridge sInstance;

    private OlmPkSigningBridge(ReactApplicationContext context) {
        super(context, OlmPkSigning.class, null, "releaseSigning", "mNativeId");
    }

    public static OlmPkSigningBridge getInstance(ReactApplicationContext context) {
        if (sInstance == null) {
            sInstance = new OlmPkSigningBridge(context);
        }
        return sInstance;
    }

    @Override
    public String getName() {
        return "OlmPkSigningBridge";
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String create() throws OlmException {
        return "" + createObj();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void free(String id) {
        releaseObj(id);
    }

    // The seed parameter should be encoded into base64 from Uint8Array
    @ReactMethod(isBlockingSynchronousMethod = true)
    public String initWithSeed(String id, String seed) throws OlmException {
        OlmPkSigning sign = getObj(id);
        return sign.initWithSeed(Base64.getDecoder().decode(seed));
    }

    // The return value will be encoded in base64 (to be converted to Uint8Array)
    @ReactMethod(isBlockingSynchronousMethod = true)
    public String generateSeed(String id) throws OlmException {
        OlmPkSigning sign = getObj(id);
        return Base64.getEncoder().encodeToString(sign.generateSeed());
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String sign(String id, String message) throws OlmException {
        OlmPkSigning sign = getObj(id);
        return sign.sign(message);
    }
}