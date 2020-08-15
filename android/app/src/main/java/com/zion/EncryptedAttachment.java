package com.zion;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.WritableMap;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.security.DigestInputStream;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.CipherInputStream;
import javax.crypto.NoSuchPaddingException;
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
                byte[] key = Base64.getDecoder().decode(base64UrlToBase64(inKey));
                byte[] iv = Base64.getDecoder().decode(base64UrlToBase64(inIv));

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

    // AES-256-CTR parameters with sha256 hash digest object
    public static class EncryptionParameters {
        public byte[] key; // 256-bit (32 bytes)
        public byte[] iv; // 128-bit (16 bytes)
        public MessageDigest digest; // SHA-256
    }

    // Encrypt an InputStream using AES-256-CTR with randomly generated key and IV
    // the parameters are filled to the outParams object. It also hashes the output
    // automatically with SHA-256 (use the digest object on EncryptionParameters)
    // Unlike downloaded files, uploading is implemented based on InputStreams from
    // content URIs (see NativeUtils), because we don't want to duplicate user's
    // files in external storage to our internal cache. Duplicating is fine for
    // downloads because they need to be stored in cache anyway, and it allows
    // us to cut down on the amount of native code (HTTP downloading may be more
    // complicated than uploading as the server side decides the format and
    // everything).
    // This is not exposed to React Native directly -- it has to be called from
    // NativeUtils.
    public static InputStream encryptAndDigestStream(InputStream is, EncryptionParameters outParams)
            throws NoSuchAlgorithmException, InvalidAlgorithmParameterException,
                   NoSuchPaddingException, InvalidKeyException {
        // Generate secure params
        outParams.key = new byte[32];
        outParams.iv = new byte[16];
        SecureRandom.getInstanceStrong().nextBytes(outParams.key);
        SecureRandom.getInstanceStrong().nextBytes(outParams.iv);
        // Initialize cipher
        Cipher cipher = Cipher.getInstance("AES/CTR/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE,
            new SecretKeySpec(outParams.key, "AES"),
            new IvParameterSpec(outParams.iv));
        // Initialize the digest
        outParams.digest = MessageDigest.getInstance("SHA-256");
        return new DigestInputStream(new CipherInputStream(is, cipher), outParams.digest);
    }

    // Export encryption parameters to the JS side
    public static WritableMap buildEncryptedAttachmentInfo(EncryptionParameters params) {
        WritableMap map = Arguments.createMap();
        map.putString("encodedKey",
            Base64.getUrlEncoder().withoutPadding().encodeToString(params.key));
        map.putString("encodedIv",
            Base64.getEncoder().withoutPadding().encodeToString(params.iv));
        map.putString("encodedSha256",
            Base64.getEncoder().withoutPadding().encodeToString(params.digest.digest()));
        return map;
    }

    // We use this instead of Java's Base64.getUrlEncoder() because
    // sometimes Matrix does not encode URL-safe base64 properly.
    // Using this we can be more permissive about it
    // (i.e. do not throw when something different happens)
    private static String base64UrlToBase64(String str) {
        return str.replace("-", "+").replace("_", "/");
    }
}