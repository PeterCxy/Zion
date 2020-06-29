package org.matrix.olm;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class OlmSessionBridge extends OlmSerializableBridgeBase<OlmSession> {
    private static OlmSessionBridge sInstance;

    private OlmSessionBridge(ReactApplicationContext context) {
        super(context, OlmSession.class, "getOlmSessionId", "releaseSession");
    }

    public static OlmSessionBridge getInstance(ReactApplicationContext context) {
        if (sInstance == null) {
            sInstance = new OlmSessionBridge(context);
        }
        return sInstance;
    }

    @Override
    public String getName() {
        return "OlmSessionBridge";
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
    public String create() {
        return "" + createObj();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void free(String id) {
        releaseObj(id);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void createOutbound(String id, String accountId,
        String theirIdentKey, String theirOneTimeKey) throws OlmException {
        OlmSession session = getObj(id);
        session.initOutboundSession(
            OlmAccountBridge.getInstance(null).getObj(accountId),
            theirIdentKey, theirOneTimeKey
        );
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void createInbound(String id, String accountId,
        String oneTimeKeyMsg) throws OlmException {
        OlmSession session = getObj(id);
        session.initInboundSession(
            OlmAccountBridge.getInstance(null).getObj(accountId),
            oneTimeKeyMsg
        );
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void createInboundFrom(String id, String accountId,
        String identKey, String oneTimeKeyMsg) throws OlmException {
        OlmSession session = getObj(id);
        session.initInboundSessionFrom(
            OlmAccountBridge.getInstance(null).getObj(accountId),
            identKey, oneTimeKeyMsg
        );
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String sessionId(String id) throws OlmException {
        OlmSession session = getObj(id);
        return session.sessionIdentifier();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public boolean hasReceivedMessage(String id) {
        // This seems to be not important and not present in the Java SDK
        // The JS SDK requires it but does not seem to actually use it anywhere
        return true;
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public boolean matchesInbound(String id, String oneTimeKeyMsg) throws OlmException {
        OlmSession session = getObj(id);
        if (session != null) {
            return session.matchesInboundSession(oneTimeKeyMsg);
        } else {
            return false;
        }
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public boolean matchesInboundFrom(String id, String identKey,
        String oneTimeKeyMsg) throws OlmException {
        OlmSession session = getObj(id);
        return session.matchesInboundSessionFrom(identKey, oneTimeKeyMsg);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String encrypt(String id, String plaintext) throws OlmException {
        OlmSession session = getObj(id);
        return session.encryptMessage(plaintext).mCipherText;
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String decrypt(String id, double msgType, String message) throws OlmException {
        OlmSession session = getObj(id);
        OlmMessage olmMsg = new OlmMessage();
        olmMsg.mType = (long) msgType;
        olmMsg.mCipherText = message;
        return session.decryptMessage(olmMsg);
    }
}