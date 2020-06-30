package com.zion;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.security.MessageDigest;
import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public class EncryptedAttachment extends ReactContextBaseJavaModule {
    public EncryptedAttachment(ReactApplicationContext context) {
        super(context);
    }

    @Override
    public String getName() {
        return "EncryptedAttachment";
    }

    @ReactMethod
    public void decrypt(String srcPath, String dstPath,
        String inIv, String inKey, String hash, Promise promise) {
        // Do not block the main thread -- we use Promise anyway
        new Thread(() -> {
            try {
                byte[] key = Base64.getUrlDecoder().decode(inKey);
                byte[] iv = Base64.getUrlDecoder().decode(inIv);

                Cipher cipher = Cipher.getInstance("AES/CTR/NoPadding");
                cipher.init(Cipher.DECRYPT_MODE,
                    new SecretKeySpec(key, "AES"),
                    new IvParameterSpec(iv));

                MessageDigest digest = MessageDigest.getInstance("SHA-256");

                FileInputStream is = new FileInputStream(new File(srcPath));
                FileOutputStream os = new FileOutputStream(new File(dstPath));

                int read;
                byte[] buf = new byte[32 * 1024];
                byte[] clearBytes;

                while ((read = is.read(buf)) != -1) {
                    digest.update(buf, 0, read);
                    clearBytes = cipher.update(buf, 0, read);
                    os.write(clearBytes);
                }

                clearBytes = cipher.doFinal();
                os.write(clearBytes);

                String digestStr = Base64.getEncoder().withoutPadding()
                    .encodeToString(digest.digest());

                if (!digestStr.equals(hash)) {
                    promise.reject("hash mismatch, expected = " + hash + ", actual = " + digestStr);
                    return;
                }

                os.flush();
                os.close();
                is.close();
                promise.resolve(null);
            } catch (Exception e) {
                e.printStackTrace();
                promise.reject("Something went wrong on Java side, see log output");
            }
        }).start();
    }
}