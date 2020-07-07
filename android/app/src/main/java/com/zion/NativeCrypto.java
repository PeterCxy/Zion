package com.zion;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.WritableMap;

import java.io.UnsupportedEncodingException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import java.util.Arrays;
import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.Mac;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;

// Native crypto implementation for matrix-js-sdk local secret storage
// used in vendor/matrix-js-sdk/src/crypto/aes.js
// We DO need to replicate the Node / Browser version.
public class NativeCrypto extends ReactContextBaseJavaModule {
    public NativeCrypto(ReactApplicationContext context) {
        super(context);
    }

    @Override
    public String getName() {
        return "NativeCrypto";
    }

    // Encrypt a string natively
    // Key must be encoded in base64
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
                byte[] cipherBytes = cipher.doFinal(data.getBytes("UTF-8"));
                String cipherText =
                    Base64.getEncoder().encodeToString(cipherBytes);

                // HMAC
                Mac mac = Mac.getInstance("HmacSHA256");
                SecretKeySpec macSpec = new SecretKeySpec(keys[1], "HmacSHA256");
                mac.init(macSpec);
                String macText =
                    Base64.getEncoder().encodeToString(
                        mac.doFinal(cipherBytes));
                
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
    // key must be encoded in base64
    @ReactMethod
    public void decryptNative(String ciphertext, String iv, String hmac,
        String key, String name, Promise promise) {
        new Thread(() -> {
            try {
                byte[] ivBytes = Base64.getDecoder().decode(iv);
                byte[] cipherBytes = Base64.getDecoder().decode(ciphertext);

                byte[][] keys = deriveKeysNative(key, name);

                // HMAC
                Mac mac = Mac.getInstance("HmacSHA256");
                SecretKeySpec macSpec = new SecretKeySpec(keys[1], "HmacSHA256");
                mac.init(macSpec);
                String macText =
                    Base64.getEncoder().encodeToString(
                        mac.doFinal(cipherBytes));

                String _macText = macText.replace("=", "").replace("+", "");
                String _hmac = hmac.replace("=", "").replace("+", "");
                if (!_macText.equals(_hmac)) {
                    promise.reject("MACs do not match");
                    return;
                }

                // Decrypt
                IvParameterSpec ivSpec = new IvParameterSpec(ivBytes);
                SecretKeySpec keySpec = new SecretKeySpec(keys[0], "AES");
                Cipher cipher = Cipher.getInstance("AES/CTR/NoPadding");
                cipher.init(Cipher.DECRYPT_MODE, keySpec, ivSpec);
                byte[] res = cipher.doFinal(cipherBytes);
                promise.resolve(new String(res, "UTF-8"));
            } catch (Exception e) {
                promise.reject(e.getMessage());
            }
        }).start();
    }

    // HKDF with HMAC-SHA256
    private static byte[][] deriveKeysNative(String key, String name)
        throws UnsupportedEncodingException, NoSuchAlgorithmException, InvalidKeyException {
        byte[] keyBytes = Base64.getDecoder().decode(key);
        // salt for HKDF, with 8 bytes of zeros
        SecretKeySpec macSpec = new SecretKeySpec(new byte[8], "HmacSHA256");

        // prk
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(macSpec);
        mac.update(keyBytes);
        byte[] prk = mac.doFinal();
        SecretKeySpec prkSpec = new SecretKeySpec(prk, "HmacSHA256");

        byte[] b = new byte[1];
        b[0] = 1;

        // calculate aes key
        mac = Mac.getInstance("HmacSHA256");
        mac.init(prkSpec);
        mac.update(name.getBytes("UTF-8"));
        mac.update(b);
        byte[] keyAes = mac.doFinal();

        // Calculate HMAC key
        b[0] = 2;
        mac = Mac.getInstance("HmacSHA256");
        mac.init(prkSpec);
        mac.update(keyAes);
        mac.update(name.getBytes("UTF-8"));
        mac.update(b);
        byte[] keyHmac = mac.doFinal();

        return new byte[][]{keyAes, keyHmac};
    }

    // PBKDF key derivation for secret storage
    // matrix-js-sdk/src/crypto/key_passphrase.js
    // The return value is base64-encoded
    @ReactMethod
    public void deriveSecretStorageKey(String password,
        String salt, int iterations, int numBits, Promise promise) {
        new Thread(() -> {
            try {
                SecretKeyFactory skf = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA512");
                PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt.getBytes("UTF-8"), iterations, numBits);
                SecretKey key = skf.generateSecret(spec);
                promise.resolve(Base64.getEncoder().encodeToString(key.getEncoded()));
            } catch (Exception e) {
                promise.reject(e.getMessage());
            }
        }).start();
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