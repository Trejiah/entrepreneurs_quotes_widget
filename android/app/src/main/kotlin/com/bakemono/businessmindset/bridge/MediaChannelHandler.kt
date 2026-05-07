package com.bakemono.businessmindset.bridge

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * Implements `shareImageDirect` / `saveImageToGallery` on Android. The Dart
 * side passes a JPEG byte buffer keyed `imageBytes` (rendered with Flutter's
 * RepaintBoundary on Android — see [lib/services/share_quotes.dart]).
 */
object MediaChannelHandler {
    private const val TAG = "MediaChannelHandler"
    private const val SHARE_FILE_NAME = "BusinessMindset_Quote.jpg"
    private const val GALLERY_DIR = "BusinessMindset"

    fun shareImage(context: Context, call: MethodCall, result: MethodChannel.Result) {
        val bytes = (call.arguments as? Map<*, *>)?.get("imageBytes") as? ByteArray
        if (bytes == null) {
            result.error("INVALID_ARGUMENTS", "Expected imageBytes byte array", null)
            return
        }

        try {
            val cacheDir = File(context.cacheDir, "shared_images").apply { mkdirs() }
            val file = File(cacheDir, SHARE_FILE_NAME)
            // Always overwrite so the system share-sheet thumbnail refreshes.
            FileOutputStream(file).use { it.write(bytes) }

            val authority = "${context.packageName}.fileprovider"
            val uri = FileProvider.getUriForFile(context, authority, file)

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "image/jpeg"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, "Business Mindset Quote")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            val chooser = Intent.createChooser(intent, null).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(chooser)
            result.success(null)
        } catch (t: Throwable) {
            Log.e(TAG, "shareImage failed", t)
            result.error("SHARE_FAILED", t.message, null)
        }
    }

    fun saveImage(context: Context, call: MethodCall, result: MethodChannel.Result) {
        val bytes = (call.arguments as? Map<*, *>)?.get("imageBytes") as? ByteArray
        if (bytes == null) {
            result.error("INVALID_ARGUMENTS", "Expected imageBytes byte array", null)
            return
        }

        try {
            val displayName = "businessmindset_${System.currentTimeMillis()}.jpg"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveImageScopedStorage(context, displayName, bytes)
            } else {
                saveImageLegacy(displayName, bytes)
            }
            result.success(true)
        } catch (t: Throwable) {
            Log.e(TAG, "saveImage failed", t)
            result.error("SAVE_FAILED", t.message, null)
        }
    }

    private fun saveImageScopedStorage(context: Context, displayName: String, bytes: ByteArray) {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/$GALLERY_DIR")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("MediaStore.insert returned null")

        resolver.openOutputStream(uri)?.use { it.write(bytes) }
            ?: throw IllegalStateException("Cannot open output stream for $uri")

        values.clear()
        values.put(MediaStore.Images.Media.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
    }

    @Suppress("DEPRECATION")
    private fun saveImageLegacy(displayName: String, bytes: ByteArray) {
        val dir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
            GALLERY_DIR,
        ).apply { mkdirs() }
        val file = File(dir, displayName)
        FileOutputStream(file).use { it.write(bytes) }
    }
}
