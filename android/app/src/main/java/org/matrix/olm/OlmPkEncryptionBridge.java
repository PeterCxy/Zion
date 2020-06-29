package org.matrix.olm;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class OlmPkEncryptionBridge extends OlmBridgeBase<OlmPkEncryption> {
    private static OlmPkEncryptionBridge sInstance;

    private OlmPkEncryptionBridge(ReactApplicationContext context) {
        super(context, OlmPkEncryption.class, null, "releaseEncryption", "mNativeId");
    }

    public static OlmPkEncryptionBridge getInstance(ReactApplicationContext context) {
        if (sInstance == null) {
            sInstance = new OlmPkEncryptionBridge(context);
        }
        return sInstance;
    }

    @Override
    public String getName() {
        return "OlmPkEncryptionBridge";
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
    public void setRecipientKey(String id, String key) throws OlmException {
        OlmPkEncryption enc = getObj(id);
        enc.setRecipientKey(key);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String encrypt(String id, String plaintext) throws OlmException {
        OlmPkEncryption enc = getObj(id);
        return enc.encrypt(plaintext).mCipherText;
    }
}