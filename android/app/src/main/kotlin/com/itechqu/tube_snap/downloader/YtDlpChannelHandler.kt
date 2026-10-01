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

    // Player client fallback chain — ordered from most permissive (no sign-in
    // ever required) to least. tv_embedded is the YouTube TV embedded client
    // used by third-party devices; it has never required authentication and is
    // the most reliable bypass for the "Sign in to confirm" bot check.
    private val CLIENT_CHAIN = listOf("tv_embedded", "mweb", "android", "ios")

    fun setChannel(channel: MethodChannel) {
        methodChannel = channel
    }

    private fun ensureInitialized() {
        if (!isInitialized) {
            try {
                YoutubeDL.getInstance().init(context.applicationContext)
                isInitialized = true
                // Silently update yt-dlp in background so the bundled binary
                // (which may be months old) gets replaced with a version that
                // has current bot-bypass patches. Non-blocking — we don't wait
                // for this; any in-flight request uses the bundled binary and
                // the next one benefits from the update.
                executor.execute {
                    try {
                        YoutubeDL.getInstance().updateYoutubeDL(
                            context.applicationContext,
                            YoutubeDL.UpdateChannel._STABLE
                        )
                        Log.i("YtDlpChannelHandler", "yt-dlp updated to latest stable")
                    } catch (e: Exception) {
                        Log.w("YtDlpChannelHandler", "yt-dlp background update failed (bundled version still works): ${e.message}")
                    }
                }
            } catch (e: Exception) {
                Log.e("YtDlpChannelHandler", "Failed to init youtubedl-android", e)
            }
        }
    }

    /** Builds a YoutubeDLRequest that bypasses YouTube bot detection.
     *  Uses [client] as the player_client; caller tries the CLIENT_CHAIN
     *  in order until one succeeds or all fail.
     */
    private fun buildAnalyzeRequest(url: String, client: String) =
        YoutubeDLRequest(url).apply {
            addOption("--dump-single-json")
            addOption("--no-playlist")
            addOption("--no-check-certificates")
            addOption("--no-update")
            // tv_embedded / mweb / android / ios — each is a different YouTube
            // API surface; tv_embedded never requires sign-in, making it the
            // most reliable way to fetch metadata without cookies.
            addOption("--extractor-args", "youtube:player_client=$client")
            addOption("--user-agent", "Mozilla/5.0 (ChromiumStylePlatform) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Mobile Safari/537.36")
        }

    private fun buildDownloadRequest(url: String, formatId: String, targetFilePath: String, client: String) =
        YoutubeDLRequest(url).apply {
            addOption("-f", "$formatId/bestvideo+bestaudio/best")
            addOption("-o", targetFilePath)
            addOption("--no-playlist")
            addOption("--no-check-certificates")
            addOption("--force-overwrites")
            addOption("--no-mtime")
            addOption("--no-update")
            addOption("--merge-output-format", "mp4")
            addOption("--extractor-args", "youtube:player_client=$client")
            addOption("--user-agent", "Mozilla/5.0 (ChromiumStylePlatform) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Mobile Safari/537.36")
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
                    ensureInitialized()
                    var lastError: Exception? = null
                    // Try each client in the fallback chain; stop at first success.
                    for (client in CLIENT_CHAIN) {
                        try {
                            Log.i("YtDlpChannelHandler", "Analyze attempt with client=$client url=$url")
                            val request = buildAnalyzeRequest(url, client)
                            val response = YoutubeDL.getInstance().execute(request)
                            mainHandler.post { result.success(response.out) }
                            return@execute
                        } catch (e: Exception) {
                            val msg = e.message ?: ""
                            Log.w("YtDlpChannelHandler", "Analyze client=$client failed: $msg")
                            lastError = e
                            // Only continue the chain on bot/auth errors; other errors
                            // (network, invalid URL) won't be fixed by a different client.
                            if (!msg.contains("Sign in") && !msg.contains("bot") &&
                                !msg.contains("Precondition") && !msg.contains("unable to extract")) {
                                break
                            }
                        }
                    }
                    // All clients failed — surface the last error to Dart.
                    Log.e("YtDlpChannelHandler", "Analyze failed after trying all clients", lastError)
                    mainHandler.post {
                        result.error("ANALYZE_FAILED", lastError?.message, null)
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
                    ensureInitialized()
                    val targetFile = java.io.File(targetFilePath)
                    targetFile.parentFile?.mkdirs()

                    var lastError: Exception? = null
                    for (client in CLIENT_CHAIN) {
                        try {
                            val request = buildDownloadRequest(url, formatId, targetFilePath, client)
                            Log.i("YtDlpChannelHandler", "Download attempt: client=$client taskId=$taskId url=$url format=$formatId")
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
                            Log.i("YtDlpChannelHandler", "Download finished: client=$client taskId=$taskId exitCode=${response.exitCode}")
                            mainHandler.post { result.success(true) }
                            return@execute
                        } catch (e: Exception) {
                            val msg = e.message ?: ""
                            lastError = e
                            val isBotError = msg.contains("Sign in") || msg.contains("bot") ||
                                msg.contains("Precondition") || msg.contains("unable to extract")
                            val is403 = msg.contains("403") || msg.contains("Forbidden") || msg.contains("older than 90 days")
                            Log.w("YtDlpChannelHandler", "Download client=$client taskId=$taskId failed (bot=$isBotError 403=$is403): $msg")
                            if (!isBotError && !is403) break
                        }
                    }

                    // All clients failed — try updating yt-dlp then one final retry.
                    try {
                        Log.w("YtDlpChannelHandler", "All clients failed. Updating yt-dlp and retrying once...")
                        YoutubeDL.getInstance().updateYoutubeDL(context.applicationContext, YoutubeDL.UpdateChannel._STABLE)
                        val request = buildDownloadRequest(url, formatId, targetFilePath, CLIENT_CHAIN[0])
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
                        Log.i("YtDlpChannelHandler", "Post-update retry succeeded: exitCode=${retryResponse.exitCode}")
                        mainHandler.post { result.success(true) }
                    } catch (retryEx: Exception) {
                        Log.e("YtDlpChannelHandler", "Post-update retry also failed: ${retryEx.message}", retryEx)
                        mainHandler.post { result.error("DOWNLOAD_FAILED", lastError?.message ?: "Unknown download error", null) }
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
