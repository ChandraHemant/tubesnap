package com.itechqu.tube_snap.downloader

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLException
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class YtDlpChannelHandler(
    private val context: Context,
) : MethodChannel.MethodCallHandler {

    private val executor = Executors.newFixedThreadPool(4)
    private val mainHandler = Handler(Looper.getMainLooper())
    private var methodChannel: MethodChannel? = null
    private var isInitialized = false

    fun setChannel(channel: MethodChannel) {
        methodChannel = channel
    }

    private fun ensureInitialized() {
        if (!isInitialized) {
            try {
                YoutubeDL.getInstance().init(context.applicationContext)
                isInitialized = true
            } catch (e: Exception) {
                Log.e("YtDlpChannelHandler", "Failed to init youtubedl-android", e)
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> {
                executor.execute {
                    try {
                        ensureInitialized()
                        mainHandler.post { result.success(true) }
                    } catch (e: Exception) {
                        mainHandler.post { result.error("INIT_FAILED", e.message, null) }
                    }
                }
            }
            "getVersion" -> {
                executor.execute {
                    try {
                        ensureInitialized()
                        val version = YoutubeDL.getInstance().version(context.applicationContext)
                        mainHandler.post { result.success(version) }
                    } catch (e: Exception) {
                        mainHandler.post { result.success(null) }
                    }
                }
            }
            "updateEngine" -> {
                executor.execute {
                    try {
                        ensureInitialized()
                        val status = YoutubeDL.getInstance().updateYoutubeDL(context.applicationContext, YoutubeDL.UpdateChannel._STABLE)
                        val version = YoutubeDL.getInstance().version(context.applicationContext)
                        mainHandler.post {
                            result.success(
                                mapOf(
                                    "status" to (status?.name ?: "DONE"),
                                    "version" to (version ?: "")
                                )
                            )
                        }
                    } catch (e: Exception) {
                        Log.e("YtDlpChannelHandler", "Update failed: ${e.message}", e)
                        mainHandler.post { result.error("UPDATE_FAILED", e.message, null) }
                    }
                }
            }
            "analyze" -> {
                val url = call.argument<String>("url") ?: run {
                    result.error("INVALID_ARGS", "URL is required", null)
                    return
                }
                executor.execute {
                    try {
                        ensureInitialized()
                        val request = YoutubeDLRequest(url).apply {
                            addOption("--dump-single-json")
                            addOption("--no-playlist")
                            addOption("--no-check-certificates")
                            addOption("--no-update")
                            // Use android+mweb clients: avoids the "Sign in to confirm" bot check
                            // that YouTube shows to the default web client on new installs.
                            addOption("--extractor-args", "youtube:player_client=android,mweb")
                            addOption("--user-agent", "com.google.android.youtube/19.09.36 (Linux; U; Android 11) gzip")
                        }
                        val response = YoutubeDL.getInstance().execute(request)
                        mainHandler.post { result.success(response.out) }
                    } catch (e: Exception) {
                        Log.e("YtDlpChannelHandler", "Analyze failed: ${e.message}", e)
                        mainHandler.post { result.error("ANALYZE_FAILED", e.message, null) }
                    }
                }
            }
            "download" -> {
                val taskId = call.argument<String>("taskId") ?: ""
                val url = call.argument<String>("url") ?: ""
                val formatId = call.argument<String>("formatId") ?: "best"
                val targetFilePath = call.argument<String>("targetFilePath") ?: ""

                if (url.isEmpty() || targetFilePath.isEmpty()) {
                    result.error("INVALID_ARGS", "URL and targetFilePath are required", null)
                    return
                }

                executor.execute {
                    val request = YoutubeDLRequest(url).apply {
                        addOption("-f", "$formatId/bestvideo/best")
                        addOption("-o", targetFilePath)
                        addOption("--no-playlist")
                        addOption("--no-check-certificates")
                        addOption("--force-overwrites")
                        addOption("--no-mtime")
                        addOption("--no-update")
                        // android+mweb avoids the "Sign in to confirm" bot check
                        addOption("--extractor-args", "youtube:player_client=android,mweb")
                        addOption("--user-agent", "com.google.android.youtube/19.09.36 (Linux; U; Android 11) gzip")
                    }

                    try {
                        ensureInitialized()
                        val targetFile = java.io.File(targetFilePath)
                        targetFile.parentFile?.mkdirs()

                        Log.i("YtDlpChannelHandler", "Starting download: url=$url, format=$formatId, target=$targetFilePath, taskId=$taskId")
                        val response = YoutubeDL.getInstance().execute(request, taskId) { progress, etaInSeconds, line ->
                            mainHandler.post {
                                methodChannel?.invokeMethod(
                                    "onProgress",
                                    mapOf(
                                        "taskId" to taskId,
                                        "progress" to progress.toDouble(),
                                        "eta" to etaInSeconds,
                                        "line" to (line ?: "")
                                    )
                                )
                            }
                        }
                        Log.i("YtDlpChannelHandler", "Download finished: taskId=$taskId exitCode=${response.exitCode}")
                        mainHandler.post { result.success(true) }
                    } catch (e: Exception) {
                        val errMsg = e.message ?: ""
                        if (errMsg.contains("403") || errMsg.contains("older than 90 days") || errMsg.contains("Forbidden")) {
                            Log.w("YtDlpChannelHandler", "Encountered 403 / version issue. Attempting auto-update of yt-dlp...")
                            try {
                                YoutubeDL.getInstance().updateYoutubeDL(context.applicationContext, YoutubeDL.UpdateChannel._STABLE)
                                Log.i("YtDlpChannelHandler", "Updated yt-dlp to latest. Retrying download once...")
                                val retryResponse = YoutubeDL.getInstance().execute(request, taskId) { progress, etaInSeconds, line ->
                                    mainHandler.post {
                                        methodChannel?.invokeMethod(
                                            "onProgress",
                                            mapOf(
                                                "taskId" to taskId,
                                                "progress" to progress.toDouble(),
                                                "eta" to etaInSeconds,
                                                "line" to (line ?: "")
                                            )
                                        )
                                    }
                                }
                                Log.i("YtDlpChannelHandler", "Retry succeeded with exitCode=${retryResponse.exitCode}")
                                mainHandler.post { result.success(true) }
                                return@execute
                            } catch (retryEx: Exception) {
                                Log.e("YtDlpChannelHandler", "Retry after update also failed: ${retryEx.message}", retryEx)
                            }
                        }

                        Log.e("YtDlpChannelHandler", "Download failed for taskId=$taskId: ${e.message}", e)
                        mainHandler.post { result.error("DOWNLOAD_FAILED", e.message ?: "Unknown download error", null) }
                    }
                }
            }
            "cancel" -> {
                val taskId = call.argument<String>("taskId") ?: ""
                if (taskId.isNotEmpty()) {
                    try {
                        YoutubeDL.getInstance().destroyProcessById(taskId)
                    } catch (e: Exception) {
                        Log.w("YtDlpChannelHandler", "Error canceling task $taskId: ${e.message}")
                    }
                }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}

