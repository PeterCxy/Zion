package org.matrix.olm;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;

import java.io.Serializable;
import java.util.Base64;

abstract class OlmSerializableBridgeBase<T extends CommonSerializeUtils> extends OlmBridgeBase<T> {
    public OlmSerializableBridgeBase(ReactApplicationContext context, Class<T> clazz,
        String getIdMethodName, String releaseMethodName) {
        this(context, clazz, getIdMethodName, releaseMethodName, null);    
    }

    public OlmSerializableBridgeBase(ReactApplicationContext context, Class<T> clazz,
        String getIdMethodName, String releaseMethodName, String idFieldName) {
        super(context, clazz, getIdMethodName, releaseMethodName, idFieldName);
    }

    public String serialize(String id, String key) {
        StringBuffer errMsg = new StringBuffer();
        T obj = super.getObj(id);
        byte[] res = obj.serialize(key.getBytes(), errMsg);
        if (res != null)
            return Base64.getEncoder().encodeToString(res);
        else 
            return null;
    }

    public String deserialize(String key, String pickle) throws Exception {
        T obj = super.instantiateObj();
        obj.deserialize(Base64.getDecoder().decode(pickle), key.getBytes());
        return "" + super.putObj(obj);
    }
}