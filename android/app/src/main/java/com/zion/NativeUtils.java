package com.zion;

import android.app.Activity;
import android.content.Context;
import android.content.ClipData;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.provider.OpenableColumns;

import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.WritableMap;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.util.stream.Collectors;

public class NativeUtils extends ReactContextBaseJavaModule {
    private ReactApplicationContext mContext;

    public NativeUtils(ReactApplicationContext context) {
        super(context);
        mContext = context;
    }

    @Override
    public String getName() {
        return "NativeUtils";
    }

    @ReactMethod
    public void openURL(String url) {
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        mContext.startActivity(intent);
    }

    // Open a file in internal cache path (FS_CACHE_PATH) in other applications
    // Since our internal cached files do not keep the original name, the name
    // must be passed via the second argument
    @ReactMethod
    public void openFile(String path, String name) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setData(
            RemapFileProvider.getUriForFileRename(mContext,
                "im.angry.zion.fileprovider", new File(path), name));
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        mContext.startActivity(intent);
    }

    // Save a file to external storage, asking user to choose the destination
    @ReactMethod
    public void saveFileToExternal(String path, String name, String mime, Promise promise) {
        final Activity activity = getCurrentActivity();

        if (activity != null && activity instanceof MainActivity) {
            ((MainActivity) activity).saveFileToExternal(path, name, mime, promise);
        } else {
            promise.reject("No activity found");
        }
    }

    // Share a file in internal cache to other applications
    @ReactMethod
    public void shareFile(String path, String name, String mime, String chooserTitle) {
        Intent intent = new Intent(Intent.ACTION_SEND);
        Uri uri = RemapFileProvider.getUriForFileRename(mContext,
            "im.angry.zion.fileprovider", new File(path), name);
        intent.setClipData(new ClipData(
            name, new String[]{mime},
            new ClipData.Item(uri)));
        intent.putExtra(Intent.EXTRA_STREAM, uri);
        intent.setType(mime);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

        // The chooser must be started from a real activity
        final Activity activity = getCurrentActivity();

        if (activity != null)
            activity.startActivity(Intent.createChooser(intent, chooserTitle));
    }

    // Request the user to choose a file from storage or other applications
    // used for uploading attachments
    // Returns the content URI to the file
    @ReactMethod
    public void openDocument(Promise promise) {
        final Activity activity = getCurrentActivity();

        if (activity != null)
            ((MainActivity) activity).openDocument(promise);
    }

    // Upload a content Uri opened by openDocument() to a matrix media repository,
    // returning the mxc:// url
    @ReactMethod
    public void uploadContentUri(String baseUrl, String token, String contentUri, Promise promise) {
        Uri uri = Uri.parse(contentUri);
        String name = getContentUriName(uri);
        String mime = getContentUriMime(uri);
        int size = getContentUriSize(uri);

        if (name == null || mime == null) {
            promise.reject("Cannot retrieve information about the uri");
            return;
        }

        new Thread(() -> {
            DeviceEventManagerModule.RCTDeviceEventEmitter emitter = mContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class);
            try (
                InputStream is = mContext.getContentResolver().openInputStream(uri);
            ) {
                String result = uploadMedia(baseUrl, token, name, mime, is, (uploaded) -> {
                    WritableMap params = Arguments.createMap();
                    params.putInt("total", size);
                    params.putInt("uploaded", uploaded);
                    emitter.emit("onProgress_" + contentUri, params);
                });
                if (result != null)
                    promise.resolve(result);
                else
                    promise.reject("unknown error");
            } catch (Exception e) {
                promise.reject(e.getMessage());
            }
        }).start();
    }

    private String getContentUriName(Uri uri) {
        Cursor cursor = mContext.getContentResolver().query(uri, null, null, null, null);
        try {
            if (cursor != null && cursor.moveToFirst()) {
                return cursor.getString(cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME));
            } else {
                return null;
            }
        } finally {
          cursor.close();
        }
    }

    private int getContentUriSize(Uri uri) {
        Cursor cursor = mContext.getContentResolver().query(uri, null, null, null, null);
        try {
            if (cursor != null && cursor.moveToFirst()) {
                return cursor.getInt(cursor.getColumnIndex(OpenableColumns.SIZE));
            } else {
                return -1;
            }
        } finally {
          cursor.close();
        }
    }

    private String getContentUriMime(Uri uri) {
        return mContext.getContentResolver().getType(uri);
    }

    interface UploadProgressListener {
        void onProgress(int uploaded);
    }

    // We have to re-implement this outside of matrix-js-sdk
    // because the one in matrix-js-sdk cannot stream its input
    // under React Native, which requires us to read the whole
    // file into memory, which is a terrible idea.
    // We could have copied the file to our private storage
    // and reuse rn-fetch-blob instead, but I figured it's
    // probably not the best idea either.
    private String uploadMedia(
            String baseUrl, String token, String name, String mime,
            InputStream is, UploadProgressListener listener) throws IOException, JSONException {
        URL url = new URL(baseUrl + "/_matrix/media/r0/upload?filename=" + URLEncoder.encode(name, "UTF-8"));
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Authorization", "Bearer " + token);
        conn.setRequestProperty("Content-Type", mime);
        conn.setDoOutput(true);

        try (
            OutputStream os = conn.getOutputStream();
        ) {
            byte[] buf = new byte[4096];
            int len;
            int acc = 0;
            int lastReport = 0;
            while ((len = is.read(buf)) > 0) {
                os.write(buf, 0, len);
                acc += len;
                if (listener != null && acc - lastReport >= 20480) {
                    // Throttled progress events
                    listener.onProgress(acc);
                    lastReport = acc;
                }
            }
            os.flush();

            if (conn.getResponseCode() != 200) {
                throw new RuntimeException("Server rejected with " + conn.getResponseCode());
            }

            InputStream urlIs = conn.getInputStream();
            String jsonResp = new BufferedReader(new InputStreamReader(urlIs)).lines().collect(Collectors.joining("\n"));
            urlIs.close();

            JSONObject obj = new JSONObject(jsonResp);
            return obj.getString("content_uri");
        } catch (IOException | JSONException | RuntimeException e) {
            throw e;
        } finally {
            conn.disconnect();
        }
    }
}