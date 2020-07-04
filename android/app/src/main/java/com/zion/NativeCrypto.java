package com.zion;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.WritableMap;

import java.io.UnsupportedEncodingException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import java.util.Arrays;
import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.Mac;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;

// Native crypto implementation for matrix-js-sdk local secret storage
// used in vendor/matrix-js-sdk/src/crypto/aes.js
// These are only used in local storage so we do not need to replicate
// the original algorithm exactly.
public class NativeCrypto extends ReactContextBaseJavaModule {
    public NativeCrypto(ReactApplicationContext context) {
        super(context);
    }

    @Override
    public String getName() {
        return "NativeCrypto";
    }

    // Encrypt a string natively
    // Key can be anything, since it will be used to derive encryption keys
    // (but it must be a string, which is different from the JS-side API)
    // IV should be base64-encoded
    // If iv is null, a new one is generated randomly
    // returned ciphertext will also be in base64
    @ReactMethod
    public void encryptNative(String data, String key, String name,
        String iv, Promise promise) {
        new Thread(() -> {
            try {
                byte[] ivBytes;

                if (iv != null) {
                    ivBytes = Base64.getDecoder().decode(iv);
                } else {
                    ivBytes = getRandomKey(16);
                }

                byte[][] keys = deriveKeysNative(key, name);

                // AES-256-CTR encryption
                IvParameterSpec ivSpec = new IvParameterSpec(ivBytes);
                SecretKeySpec keySpec = new SecretKeySpec(keys[0], "AES");
                Cipher cipher = Cipher.getInstance("AES/CTR/NoPadding");
                cipher.init(Cipher.ENCRYPT_MODE, keySpec, ivSpec);
                String cipherText =
                    Base64.getEncoder().encodeToString(
                        cipher.doFinal(data.getBytes("UTF-8")));

                // HMAC
                Mac mac = Mac.getInstance("HmacSHA256");
                SecretKeySpec macSpec = new SecretKeySpec(keys[1], "HmacSHA256");
                mac.init(macSpec);
                String macText =
                    Base64.getEncoder().encodeToString(
                        mac.doFinal(cipherText.getBytes("UTF-8")));
                
                // Return value, the same as the JS version
                WritableMap map = Arguments.createMap();
                map.putString("iv", Base64.getEncoder().encodeToString(ivBytes));
                map.putString("ciphertext", cipherText);
                map.putString("mac", macText);
                promise.resolve(map);
            } catch (Exception e) {
                promise.reject(e.getMessage());
            }
        }).start();
    }

    // Decrypt a string natively
    // ciphertext, iv, hmac must be base64-encoded
    // key can ba any String, but the JS side uses Uint8Array so conversion
    // is needed in JS. A simple base64 will do.
    @ReactMethod
    public void decryptNative(String ciphertext, String iv, String hmac,
        String key, String name, Promise promise) {
        new Thread(() -> {
            try {
                byte[] ivBytes = Base64.getDecoder().decode(iv);

                byte[][] keys = deriveKeysNative(key, name);

                // HMAC
                Mac mac = Mac.getInstance("HmacSHA256");
                SecretKeySpec macSpec = new SecretKeySpec(keys[1], "HmacSHA256");
                mac.init(macSpec);
                String macText =
                    Base64.getEncoder().encodeToString(
                        mac.doFinal(ciphertext.getBytes("UTF-8")));

                if (!macText.equals(hmac)) {
                    promise.reject("MACs do not match");
                    return;
                }

                // Decrypt
                IvParameterSpec ivSpec = new IvParameterSpec(ivBytes);
                SecretKeySpec keySpec = new SecretKeySpec(keys[0], "AES");
                Cipher cipher = Cipher.getInstance("AES/CTR/NoPadding");
                cipher.init(Cipher.DECRYPT_MODE, keySpec, ivSpec);
                byte[] res = cipher.doFinal(Base64.getDecoder().decode(ciphertext));
                promise.resolve(new String(res, "UTF-8"));
            } catch (Exception e) {
                promise.reject(e.getMessage());
            }
        }).start();
    }

    private static byte[][] deriveKeysNative(String key, String name)
        throws UnsupportedEncodingException, NoSuchAlgorithmException, InvalidKeySpecException {
        PBEKeySpec spec = new PBEKeySpec(key.toCharArray(), name.getBytes("UTF-8"), 4096, 64 * 8);
        SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1");
        byte[] res = factory.generateSecret(spec).getEncoded();
        byte[] keyAes = Arrays.copyOfRange(res, 0, 32);
        byte[] keyHmac = Arrays.copyOfRange(res, 32, 64);
        return new byte[][]{keyAes, keyHmac};
    }

    // Copy-pasted from
    // <https://gitlab.matrix.org/matrix-org/olm/-/blob/master/android/olm-sdk/src/main/java/org/matrix/olm/OlmUtility.java>
    private static byte[] getRandomKey(int size) {
        SecureRandom secureRandom = new SecureRandom();
        byte[] buffer = new byte[size];
        secureRandom.nextBytes(buffer);

        // the key is saved as string
        // so avoid the UTF8 marker bytes
        for (int i = 0; i < size; i++) {
            buffer[i] = (byte) (buffer[i] & 0x7F);
        }
        return buffer;
    }
}