package com.zion;

import android.content.Context;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.provider.OpenableColumns;

import androidx.core.content.FileProvider;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

/*
 * A modified FileProvider that supports remapping the display names
 * of the files.
 * This is useful because Zion doesn't keep the original file name in
 * the internal cache directory, so we need some way to pass the original
 * name to the receiver applications.
 */
public class RemapFileProvider extends FileProvider {
    // It is fine to just keep the mappings in memory
    // because Zion does not grant persistable permissions to
    // other applications.
    // Instead it is only used for file sharing and opening, in
    // which case the receiver will query for the display name
    // at the moment the Uri is received.
    // If Zion somehow stopped before the display name is queried,
    // it will still not be very catastrophic as the display name
    // will simply be reverted to default.
    private static Map<Uri, String> sUriNameMap = new HashMap<>();

    public static Uri getUriForFileRename(Context context,
            String authority, File file, String newName) {
        Uri uri = FileProvider.getUriForFile(context, authority, file);
        sUriNameMap.put(uri, newName);
        return uri;
    }

    @Override
    public Cursor query(Uri uri, String[] projection,
            String selection, String[] selectionArgs, String sortOrder) {
        Cursor cursor = super.query(uri, projection, selection, selectionArgs, sortOrder);
        if (!sUriNameMap.containsKey(uri))
            return cursor;
        
        // Transform the display name
        String[] columns = cursor.getColumnNames();
        Object[] values = new Object[columns.length];
        cursor.moveToFirst();
        for (int i = 0; i < columns.length; i++) {
            if (OpenableColumns.DISPLAY_NAME.equals(columns[i])) {
                values[i] = sUriNameMap.get(uri);
            } else if (OpenableColumns.SIZE.equals(columns[i])) {
                values[i] = cursor.getInt(i);
            }
        }

        MatrixCursor ret = new MatrixCursor(columns, 1);
        ret.addRow(values);
        return ret;
    }
}