package org.matrix.olm;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.util.Base64;

public class OlmPkDecryptionBridge extends OlmBridgeBase<OlmPkDecryption> {
    private static OlmPkDecryptionBridge sInstance;

    private OlmPkDecryptionBridge(ReactApplicationContext context) {
        super(context, OlmPkDecryption.class, null, "releaseDecryption", "mNativeId");
    }

    public static OlmPkDecryptionBridge getInstance(ReactApplicationContext context) {
        if (sInstance == null) {
            sInstance = new OlmPkDecryptionBridge(context);
        }
        return sInstance;
    }

    @Override
    public String getName() {
        return "OlmPkDecryptionBridge";
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String create() throws OlmException {
        return "" + createObj();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void free(String id) {
        releaseObj(id);
    }

    // Key needs to be encoded to base64 (from Uint8Array)
    @ReactMethod(isBlockingSynchronousMethod = true)
    public String initWithPrivateKey(String id, String key) throws OlmException {
        OlmPkDecryption dec = getObj(id);
        return dec.setPrivateKey(Base64.getDecoder().decode(key));
    }

    // The returned key is base64-encoded
    // The JS side should decode it to Uint8Array
    @ReactMethod(isBlockingSynchronousMethod = true)
    public String getPrivateKey(String id) throws OlmException {
        OlmPkDecryption dec = getObj(id);
        return Base64.getEncoder().encodeToString(dec.privateKey());
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String generateKey(String id) throws OlmException {
        OlmPkDecryption dec = getObj(id);
        return dec.generateKey();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String decrypt(String id, String ephemeralKey,
        String mac, String ciphertext) throws OlmException {
        OlmPkDecryption dec = getObj(id);
        OlmPkMessage msg = new OlmPkMessage();
        msg.mCipherText = ciphertext;
        msg.mMac = mac;
        msg.mEphemeralKey = ephemeralKey;
        return dec.decrypt(msg);
    }
}