package org.matrix.olm;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class OlmReactPackage implements ReactPackage {
    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
        return Collections.emptyList();
    }

    @Override
    public List<NativeModule> createNativeModules(
                                ReactApplicationContext reactContext) {
        List<NativeModule> modules = new ArrayList<>();

        modules.add(new OlmManagerBridge(reactContext));
        modules.add(OlmAccountBridge.getInstance(reactContext));
        modules.add(OlmSessionBridge.getInstance(reactContext));
        modules.add(new OlmUtilityBridge(reactContext));
        modules.add(OlmInboundGroupSessionBridge.getInstance(reactContext));
        modules.add(OlmOutboundGroupSessionBridge.getInstance(reactContext));
        modules.add(OlmPkEncryptionBridge.getInstance(reactContext));
        modules.add(OlmPkDecryptionBridge.getInstance(reactContext));
        modules.add(OlmPkSigningBridge.getInstance(reactContext));
        modules.add(OlmSASBridge.getInstance(reactContext));

        return modules;
  }

}