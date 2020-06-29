package org.matrix.olm;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.Map;
import java.util.HashMap;

abstract class OlmBridgeBase<T> extends ReactContextBaseJavaModule {
    private HashMap<Long, T> mObjs = new HashMap<>();
    private Method mGetIdMethod;
    private Field mIdField;
    private Method mReleaseMethod;
    private Class<T> mClazz;

    protected OlmBridgeBase(ReactApplicationContext context, Class<T> clazz,
        String getIdMethodName, String releaseMethodName) {
        this(context, clazz, getIdMethodName, releaseMethodName, null);
    }

    protected OlmBridgeBase(ReactApplicationContext context, Class<T> clazz,
        String getIdMethodName, String releaseMethodName, String idFieldName) {
        super(context);
        mClazz = clazz;
        try {
            if (getIdMethodName != null) {
                mGetIdMethod = mClazz.getDeclaredMethod(getIdMethodName);
                mGetIdMethod.setAccessible(true);
            } else {
                mIdField = mClazz.getDeclaredField(idFieldName);
                mIdField.setAccessible(true);
            }
            mReleaseMethod = mClazz.getDeclaredMethod(releaseMethodName);
            mReleaseMethod.setAccessible(true);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    protected long getObjId(T obj) {
        try {
            if (mGetIdMethod != null)
                return (long) mGetIdMethod.invoke(obj);
            else
                return (long) mIdField.get(obj);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    protected T getObj(long id) {
        if (mObjs.containsKey(id)) {
            return mObjs.get(id);
        } else {
            return null;
        }
    }

    protected T getObj(String id) {
        return getObj(Long.parseLong(id));
    }

    protected long putObj(T obj) {
        long id = getObjId(obj);
        mObjs.put(id, obj);
        return id;
    }

    protected T instantiateObj() {
        try {
            return mClazz.newInstance();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    protected long createObj() {
        try {
            T obj = instantiateObj();
            return putObj(obj);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    protected void releaseObj(long id) {
        T obj = getObj(id);
        if (obj != null) {
            try {
                mReleaseMethod.invoke(obj);
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
            mObjs.remove(id);
        }
    }

    protected void releaseObj(String id) {
        releaseObj(Long.parseLong(id));
    }
}