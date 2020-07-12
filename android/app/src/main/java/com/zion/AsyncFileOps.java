package com.zion;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.util.Base64;

// The difference between RNFS and this class is that this module
// uses a separate thread for each I/O operation to prevent these
// operations from blocking each other.
// Although RN native modules do have their own threads, each module
// only has one, and that's why in RNFS we have blocking and slow
// reading issues.
public class AsyncFileOps extends ReactContextBaseJavaModule {
    public AsyncFileOps(ReactApplicationContext context) {
        super(context);
    }

    @Override
    public String getName() {
        return "AsyncFileOps";
    }

    // Read a file as standard base64 string asynchronously
    @ReactMethod
    public void readAsBase64(String path, Promise promise) {
        new Thread(() -> {
            try {
                byte[] data = Files.readAllBytes(new File(path).toPath());
                promise.resolve(Base64.getEncoder().encodeToString(data));
            } catch (Exception e) {
                promise.reject(e.getMessage());
            }
        }).start();
    }

    // Read a file as string asynchronously
    @ReactMethod
    public void readAsString(String path, Promise promise) {
        new Thread(() -> {
            try {
                byte[] data = Files.readAllBytes(new File(path).toPath());
                promise.resolve(new String(data, StandardCharsets.UTF_8));
            } catch (Exception e) {
                promise.reject(e.getMessage());
            }
        }).start();
    }

    // Write a string to a file, replacing existing content or create new
    @ReactMethod
    public void writeString(String path, String content, Promise promise) {
        new Thread(() -> {
            try {
                Files.write(
                    new File(path).toPath(),
                    content.getBytes(StandardCharsets.UTF_8),
                    StandardOpenOption.CREATE,
                    StandardOpenOption.WRITE,
                    StandardOpenOption.TRUNCATE_EXISTING
                );
                promise.resolve(null);
            } catch (Exception e) {
                promise.reject(e.getMessage());
            }
        }).start();
    }

    // Write a base64-encoded binary string to a file,
    // replacing existing content or create new
    @ReactMethod
    public void writeBase64(String path, String content, Promise promise) {
        new Thread(() -> {
            try {
                Files.write(
                    new File(path).toPath(),
                    Base64.getDecoder().decode(content),
                    StandardOpenOption.CREATE,
                    StandardOpenOption.WRITE,
                    StandardOpenOption.TRUNCATE_EXISTING
                );
                promise.resolve(null);
            } catch (Exception e) {
                promise.reject(e.getMessage());
            }
        }).start();
    }

    // Copy file from src to dst, replacing existing
    // The caller is responsible for making sure the path exists
    @ReactMethod
    public void copyFile(String src, String dst, Promise promise) {
        new Thread(() -> {
            try {
                Files.copy(new File(src).toPath(), new File(dst).toPath(),
                    StandardCopyOption.REPLACE_EXISTING);
                promise.resolve(null);
            } catch (Exception e) {
                promise.reject(e.getMessage());
            }
        }).start();
    }
}