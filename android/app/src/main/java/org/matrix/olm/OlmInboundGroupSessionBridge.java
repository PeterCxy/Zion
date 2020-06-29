package org.matrix.olm;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class OlmInboundGroupSessionBridge extends OlmSerializableBridgeBase<OlmInboundGroupSession> {
    private static OlmInboundGroupSessionBridge sInstance;

    private OlmInboundGroupSessionBridge(ReactApplicationContext context) {
        super(context, OlmInboundGroupSession.class, null, "releaseSession", "mNativeId");
    }

    public static OlmInboundGroupSessionBridge getInstance(ReactApplicationContext context) {
        if (sInstance == null) {
            sInstance = new OlmInboundGroupSessionBridge(context);
        }
        return sInstance;
    }

    @Override
    public String getName() {
        return "OlmInboundGroupSessionBridge";
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
    public String create(String sessionKey) throws OlmException {
        OlmInboundGroupSession session = new OlmInboundGroupSession(sessionKey);
        return "" + putObj(session);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void free(String id) {
        releaseObj(id);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String importSession(String sessionKey) throws OlmException {
        OlmInboundGroupSession session = OlmInboundGroupSession.importSession(sessionKey);
        return "" + putObj(session);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String decrypt(String id, String msg) throws OlmException {
        OlmInboundGroupSession session = getObj(id);
        return session.decryptMessage(msg).mDecryptedMessage;
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String sessionId(String id) throws OlmException {
        OlmInboundGroupSession session = getObj(id);
        return session.sessionIdentifier();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public double firstKnownIndex(String id) throws OlmException {
        OlmInboundGroupSession session = getObj(id);
        return (double) session.getFirstKnownIndex();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String exportSession(String id, double msgIndex) throws OlmException {
        OlmInboundGroupSession session = getObj(id);
        return session.export((long) msgIndex);
    }
}