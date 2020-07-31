package com.zion;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;

import com.facebook.react.ReactActivity;
import com.facebook.react.bridge.Promise;

import java.io.File;
import java.io.OutputStream;
import java.nio.file.Files;

public class MainActivity extends ReactActivity {
    private static final int REQUEST_SAVE_FILE = 0x1234;
    private static final int REQUEST_OPEN_FILE = 0x1235;

    private String mFileToSave = null;
    private Promise mSaveFilePromise = null;

    private Promise mOpenFilePromise = null;

    /**
     * Returns the name of the main component registered from JavaScript. This is used to schedule
     * rendering of the component.
     */
    @Override
    protected String getMainComponentName() {
      return "Zion";
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent resultData) {
        if (requestCode == REQUEST_SAVE_FILE) {
            if (resultCode == Activity.RESULT_OK) {
                Uri uri = null;
                if (resultData != null) {
                    uri = resultData.getData();
                    doSaveFile(mFileToSave, uri, mSaveFilePromise);
                }
            } else {
                mSaveFilePromise.reject("The user did not choose a location to save");
            }
            mFileToSave = null;
            mSaveFilePromise = null;
        } else if (requestCode == REQUEST_OPEN_FILE) {
            if (resultCode == Activity.RESULT_OK) {
                if (resultData != null) {
                    Uri uri = resultData.getData();
                    mOpenFilePromise.resolve(uri.toString());
                }
            } else {
                mOpenFilePromise.reject("The user cancelled the opening action");
            }
            mOpenFilePromise = null;
        }
    }

    private void doSaveFile(String source, Uri target, Promise promise) {
        new Thread(() -> {
            try {
                OutputStream os = getContentResolver().openOutputStream(target);
                Files.copy(new File(source).toPath(), os);
                os.flush();
                os.close();
            } catch (Exception e) {
                promise.reject(e.getMessage());
            }
        }).start();
    }

    void saveFileToExternal(String path, String title, String mime, Promise promise) {
        if (mFileToSave != null) {
            promise.reject("The last save was not completed");
        }

        mFileToSave = path;
        mSaveFilePromise = promise;

        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType(mime);
        intent.putExtra(Intent.EXTRA_TITLE, title);
        startActivityForResult(intent, REQUEST_SAVE_FILE);
    }

    void openDocument(Promise promise) {
        if (mOpenFilePromise != null) {
            promise.reject("Cannot execute multiple requests at once");
            return;
        }

        mOpenFilePromise = promise;

        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.setType("*/*");
        startActivityForResult(intent, REQUEST_OPEN_FILE);
    }
}
