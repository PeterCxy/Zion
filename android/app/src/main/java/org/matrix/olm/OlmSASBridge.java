package org.matrix.olm;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.util.Base64;

public class OlmSASBridge extends OlmBridgeBase<OlmSAS> {
    private static OlmSASBridge sInstance;

    private OlmSASBridge(ReactApplicationContext context) {
        super(context, OlmSAS.class, null, "releaseSas", "mNativeId");
    }

    public static OlmSASBridge getInstance(ReactApplicationContext context) {
        if (sInstance == null) {
            sInstance = new OlmSASBridge(context);
        }
        return sInstance;
    }

    @Override
    public String getName() {
        return "OlmSASBridge";
    }


    @ReactMethod(isBlockingSynchronousMethod = true)
    public String create() throws OlmException {
        return "" + createObj();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void free(String id) {
        releaseObj(id);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String getPubkey(String id) throws OlmException {
        OlmSAS sas = getObj(id);
        return sas.getPublicKey();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void setTheirKey(String id, String theirKey) throws OlmException {
        OlmSAS sas = getObj(id);
        sas.setTheirPublicKey(theirKey);
    }

    // The return value is base64-encoded
    @ReactMethod(isBlockingSynchronousMethod = true)
    public String generateBytes(String id, String info, int length) throws OlmException {
        OlmSAS sas = getObj(id);
        return Base64.getEncoder().encodeToString(sas.generateShortCode(info, length));
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String calculateMac(String id, String input, String info) throws OlmException {
        OlmSAS sas = getObj(id);
        return sas.calculateMac(input, info);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String calculateMacLongKdf(String id, String input, String info) throws OlmException {
        OlmSAS sas = getObj(id);
        return sas.calculateMacLongKdf(input, info);
    }
}