package org.matrix.olm;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import org.json.JSONObject;

public class OlmAccountBridge extends OlmSerializableBridgeBase<OlmAccount> {
    private static OlmAccountBridge sInstance;

    private OlmAccountBridge(ReactApplicationContext context) {
        super(context, OlmAccount.class, "getOlmAccountId", "releaseAccount");
    }

    public static OlmAccountBridge getInstance(ReactApplicationContext context) {
        if (sInstance == null) {
            sInstance = new OlmAccountBridge(context);
        }
        return sInstance;
    }

    @Override
    public String getName() {
        return "OlmAccountBridge";
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
    public String identityKeys(String id) throws OlmException {
        OlmAccount account = getObj(id);
        return new JSONObject(account.identityKeys()).toString();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String sign(String id, String message) throws OlmException {
        OlmAccount account = getObj(id);
        return account.signMessage(message);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String oneTimeKeys(String id) throws OlmException {
        OlmAccount account = getObj(id);
        return new JSONObject(account.oneTimeKeys()).toString();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void markKeysAsPublished(String id) throws OlmException {
        OlmAccount account = getObj(id);
        account.markOneTimeKeysAsPublished();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public double maxNumberOfOneTimeKeys(String id) throws OlmException {
        OlmAccount account = getObj(id);
        return (double) account.maxOneTimeKeys();
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void generateOneTimeKeys(String id, int numberOfKeys) throws OlmException {
        OlmAccount account = getObj(id);
        account.generateOneTimeKeys(numberOfKeys);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public void removeOneTimeKeys(String id, String sessionId) throws OlmException {
        OlmAccount account = getObj(id);
        account.removeOneTimeKeys(OlmSessionBridge.getInstance(null).getObj(sessionId));
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String pickle(String id, String key) {
        return serialize(id, key);
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    public String unpickle(String key, String pickle) throws Exception {
        return deserialize(key, pickle);
    }
}