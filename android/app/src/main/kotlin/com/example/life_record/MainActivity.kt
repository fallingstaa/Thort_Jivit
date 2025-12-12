package com.example.life_record

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.life_record/instagram"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareToInstagramStories" -> {
                    val videoPath = call.argument<String>("videoPath")
                    if (videoPath != null) {
                        val success = shareToInstagram(videoPath)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "videoPath is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun shareToInstagram(videoPath: String): Boolean {
        return try {
            val file = File(videoPath)
            if (!file.exists()) {
                return false
            }

            // Use FileProvider to get a content URI
            val videoUri = FileProvider.getUriForFile(
                this,
                "com.example.life_record.fileprovider",
                file
            )

            // Instagram Stories intent
            val intent = Intent("com.instagram.share.SHARE_STICKER_IMAGE").apply {
                setPackage("com.instagram.android")
                putExtra("sticker_image_uri", videoUri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            // Try video share intent if image doesn't work
            if (!isPackageInstalled("com.instagram.android")) {
                return false
            }

            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: Exception) {
            false
        }
    }
}
