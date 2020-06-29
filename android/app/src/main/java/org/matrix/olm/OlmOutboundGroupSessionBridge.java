package org.matrix.olm;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class OlmOutboundGroupSessionBridge extends OlmSerializableBridgeBase<OlmOutboundGroupSession> {
    private static OlmOutboundGroupSessionBridge sInstance;

    private OlmOutboundGroupSessionBridge(ReactApplicationContext context) {
        super(context, OlmOutboundGroupSession.class, null, "releaseSession", "mNativeId");
    }

    public static OlmOutboundGroupSessionBridge getInstance(ReactApplicationContext context) {
        if (sInstance == null) {
            sInstance = new OlmOutboundGroupSessionBridge(context);
        }
        return sInstance;
    }

    @Override
    public String getName() {
        return "OlmOutboundGroupSessionBridge";
    }


    @ReactMethod(isBlockingSynchronousMethod = true)
    public String pickle(String id, String key) {
        return serialize(id, key);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String unpickle(String key, String pickle) throws Exception {
        return deserialize(key, pickle);
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
    public String encrypt(String id, String plaintext) throws OlmException {
        OlmOutboundGroupSession session = getObj(id);
        return session.encryptMessage(plaintext);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String sessionId(String id) throws OlmException {
        OlmOutboundGroupSession session = getObj(id);
        return session.sessionIdentifier();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String sessionKey(String id) throws OlmException {
        OlmOutboundGroupSession session = getObj(id);
        return session.sessionKey();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public double messageIndex(String id) throws OlmException {
        OlmOutboundGroupSession session = getObj(id);
        return (double) session.messageIndex();
    }
}