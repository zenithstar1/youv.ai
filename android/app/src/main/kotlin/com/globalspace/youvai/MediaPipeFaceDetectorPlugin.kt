package com.globalspace.youvai

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.atan
import kotlin.math.atan2
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/**
 * Flutter plugin that wraps MediaPipe FaceLandmarker for real-time face
 * detection on Android.  Replaces ML Kit face detection with a bundled
 * model that works consistently across all devices — no Google Play Services
 * dependency.
 *
 * Method channel: `com.globalspace.youvai/mediapipe_face`
 *
 * Methods:
 *   initialize   → downloads model (if needed) + creates FaceLandmarker
 *   processFrame → processes NV21/BGRA camera bytes → face data map
 *   processImageFile → processes JPEG/PNG file → face data map
 *   dispose      → releases resources
 */
class MediaPipeFaceDetectorPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var faceLandmarker: FaceLandmarker? = null
    private val executor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "MediaPipeFace-worker").apply {
            isDaemon = true
            setUncaughtExceptionHandler { _, throwable ->
                Log.e("MediaPipeFace", "Uncaught error in worker thread", throwable)
            }
        }
    }
    private val mainHandler = Handler(Looper.getMainLooper())

    // ── MediaPipe landmark indices mapped to ML Kit 10-point format ──
    companion object {
        private const val TAG = "MediaPipeFace"
        private const val MODEL_FILE_NAME = "face_landmarker.task"
        private const val MODEL_URL =
            "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/latest/face_landmarker.task"
        private const val MODEL_MIN_SIZE = 1_000_000L // 1 MB sanity check

        // MediaPipe 478-landmark indices ↔ ML Kit FaceLandmarkType
        private const val MP_NOSE_TIP     = 1    // noseBase
        private const val MP_LEFT_EYE     = 159  // leftEye (upper centre)
        private const val MP_RIGHT_EYE    = 386  // rightEye (upper centre)
        private const val MP_LEFT_EAR     = 234  // leftEar (face edge)
        private const val MP_RIGHT_EAR    = 454  // rightEar (face edge)
        private const val MP_LEFT_MOUTH   = 61   // leftMouth
        private const val MP_RIGHT_MOUTH  = 291  // rightMouth
        private const val MP_LEFT_CHEEK   = 116  // leftCheek
        private const val MP_RIGHT_CHEEK  = 345  // rightCheek
        private const val MP_BOTTOM_MOUTH = 17   // bottomMouth

        private val LANDMARK_MAP = intArrayOf(
            MP_NOSE_TIP, MP_LEFT_EYE, MP_RIGHT_EYE,
            MP_LEFT_EAR, MP_RIGHT_EAR,
            MP_LEFT_MOUTH, MP_RIGHT_MOUTH,
            MP_LEFT_CHEEK, MP_RIGHT_CHEEK,
            MP_BOTTOM_MOUTH
        )

        // Euler angle landmark references (from full 478 set)
        private const val MP_FOREHEAD = 10
        private const val MP_CHIN     = 152
    }

    // ────────────────────────────────────────────────────────────────
    // Flutter plugin lifecycle
    // ────────────────────────────────────────────────────────────────
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            binding.binaryMessenger,
            "com.globalspace.youvai/mediapipe_face"
        )
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        faceLandmarker?.close()
        faceLandmarker = null
        executor.shutdownNow()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize"       -> handleInitialize(result)
            "processFrame"     -> handleProcessFrame(call, result)
            "processImageFile" -> handleProcessImageFile(call, result)
            "dispose"          -> handleDispose(result)
            else               -> result.notImplemented()
        }
    }

    // ────────────────────────────────────────────────────────────────
    // initialize — load model + create FaceLandmarker
    // ────────────────────────────────────────────────────────────────
    private fun handleInitialize(result: MethodChannel.Result) {
        executor.execute {
            try {
                Log.i(TAG, "Initializing MediaPipe FaceLandmarker...")

                // Strategy 1: Load directly from bundled APK assets (fastest)
                val landmarker = try {
                    createLandmarkerFromAsset(Delegate.GPU).also {
                        Log.i(TAG, "Loaded from assets with GPU delegate")
                    }
                } catch (gpuErr: Throwable) {
                    Log.w(TAG, "GPU from assets failed: ${gpuErr.message}")
                    try {
                        createLandmarkerFromAsset(Delegate.CPU).also {
                            Log.i(TAG, "Loaded from assets with CPU delegate")
                        }
                    } catch (cpuErr: Throwable) {
                        Log.w(TAG, "CPU from assets failed: ${cpuErr.message}")
                        // Strategy 2: Copy to file then load (handles edge cases)
                        val modelFile = ensureModelAvailable()
                        try {
                            createLandmarkerFromFile(modelFile, Delegate.GPU)
                        } catch (_: Throwable) {
                            createLandmarkerFromFile(modelFile, Delegate.CPU)
                        }
                    }
                }

                faceLandmarker = landmarker
                Log.i(TAG, "FaceLandmarker ready ✓")
                mainHandler.post { result.success(true) }
            } catch (e: Throwable) {
                Log.e(TAG, "Init FAILED: ${e.message}", e)
                mainHandler.post {
                    result.error("INIT_FAILED", "MediaPipe init: ${e.message}", null)
                }
            }
        }
    }

    private fun createLandmarkerFromAsset(delegate: Delegate): FaceLandmarker {
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(MODEL_FILE_NAME)
            .setDelegate(delegate)
            .build()

        val options = FaceLandmarker.FaceLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.IMAGE)
            .setNumFaces(1)
            .setMinFaceDetectionConfidence(0.3f)
            .setMinFacePresenceConfidence(0.3f)
            .build()

        return FaceLandmarker.createFromOptions(context, options)
    }

    private fun ensureModelAvailable(): File {
        val modelFile = File(context.filesDir, MODEL_FILE_NAME)
        if (modelFile.exists() && modelFile.length() > MODEL_MIN_SIZE) {
            return modelFile
        }

        // 1) Copy from bundled APK assets (instant, no network needed)
        try {
            context.assets.open(MODEL_FILE_NAME).use { input ->
                FileOutputStream(modelFile).use { output ->
                    input.copyTo(output, bufferSize = 8192)
                }
            }
            if (modelFile.length() > MODEL_MIN_SIZE) {
                return modelFile
            }
            modelFile.delete()
        } catch (_: Exception) {
            // Asset not bundled — fall through to network download
        }

        // 2) Download from Google's CDN as fallback
        val url = URL(MODEL_URL)
        val connection = url.openConnection() as HttpURLConnection
        connection.connectTimeout = 30_000
        connection.readTimeout = 60_000
        connection.requestMethod = "GET"

        try {
            val input = connection.inputStream
            val tmpFile = File(context.filesDir, "$MODEL_FILE_NAME.tmp")
            FileOutputStream(tmpFile).use { output ->
                input.copyTo(output, bufferSize = 8192)
            }
            input.close()

            if (tmpFile.length() > MODEL_MIN_SIZE) {
                modelFile.delete()
                tmpFile.renameTo(modelFile)
            } else {
                tmpFile.delete()
                throw Exception("Downloaded model too small: ${tmpFile.length()} bytes")
            }
        } finally {
            connection.disconnect()
        }

        return modelFile
    }

    private fun createLandmarkerFromFile(modelFile: File, delegate: Delegate): FaceLandmarker {
        val modelBuffer = ByteBuffer.wrap(modelFile.readBytes())

        val baseOptions = BaseOptions.builder()
            .setModelAssetBuffer(modelBuffer)
            .setDelegate(delegate)
            .build()

        val options = FaceLandmarker.FaceLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.IMAGE)
            .setNumFaces(1)
            .setMinFaceDetectionConfidence(0.3f)
            .setMinFacePresenceConfidence(0.3f)
            .build()

        return FaceLandmarker.createFromOptions(context, options)
    }

    // ────────────────────────────────────────────────────────────────
    // processFrame — camera stream byte processing
    // ────────────────────────────────────────────────────────────────
    private var frameCount = 0
    private var detectCount = 0

    private fun handleProcessFrame(call: MethodCall, result: MethodChannel.Result) {
        val bytes     = call.argument<ByteArray>("bytes")
        val width     = call.argument<Int>("width") ?: 0
        val height    = call.argument<Int>("height") ?: 0
        val rotation  = call.argument<Int>("rotation") ?: 0
        val format    = call.argument<String>("format") ?: "nv21"

        if (bytes == null || width == 0 || height == 0) {
            result.success(mapOf("hasFace" to false))
            return
        }

        val landmarker = faceLandmarker
        if (landmarker == null) {
            if (frameCount == 0) Log.w(TAG, "processFrame called but landmarker is null")
            result.success(mapOf("hasFace" to false))
            return
        }

        executor.execute {
            try {
                frameCount++
                val bitmap = when (format) {
                    "bgra8888" -> bgraToBitmap(bytes, width, height)
                    "y_only"   -> yOnlyToBitmap(bytes, width, height)
                    else       -> {
                        // Legacy NV21 path — try NV21 first, fall back to Y-only
                        try {
                            nv21ToBitmap(bytes, width, height)
                        } catch (e: Throwable) {
                            Log.w(TAG, "NV21 decode failed, using Y-only fallback")
                            yOnlyToBitmap(bytes, width, height)
                        }
                    }
                }

                val rotated = if (rotation != 0) rotateBitmap(bitmap, rotation.toFloat()) else bitmap
                val processed = maybeDownscale(rotated, 640)
                val resultMap = detectFace(landmarker, processed)

                if (resultMap["hasFace"] == true) detectCount++

                // Log first few frames and periodic status
                if (frameCount <= 3 || (frameCount % 60 == 0)) {
                    Log.i(TAG, "Frame #$frameCount: ${width}x${height} fmt=$format rot=$rotation " +
                            "hasFace=${resultMap["hasFace"]} (detected $detectCount/${frameCount})")
                }

                if (processed !== rotated) processed.recycle()
                if (rotated !== bitmap) rotated.recycle()
                bitmap.recycle()

                mainHandler.post { result.success(resultMap) }
            } catch (e: Throwable) {
                Log.e(TAG, "processFrame error: ${e.message}")
                mainHandler.post { result.success(mapOf("hasFace" to false)) }
            }
        }
    }

    // ────────────────────────────────────────────────────────────────
    // processImageFile — still image validation
    // ────────────────────────────────────────────────────────────────
    private fun handleProcessImageFile(call: MethodCall, result: MethodChannel.Result) {
        val imagePath = call.argument<String>("imagePath")
        if (imagePath == null) {
            result.success(mapOf("hasFace" to false))
            return
        }

        val landmarker = faceLandmarker
        if (landmarker == null) {
            result.success(mapOf("hasFace" to false))
            return
        }

        executor.execute {
            try {
                val bitmap = BitmapFactory.decodeFile(imagePath)
                if (bitmap == null) {
                    mainHandler.post { result.success(mapOf("hasFace" to false)) }
                    return@execute
                }

                val processed = maybeDownscale(bitmap, 1024)
                val resultMap = detectFace(landmarker, processed)

                if (processed !== bitmap) processed.recycle()
                bitmap.recycle()

                mainHandler.post { result.success(resultMap) }
            } catch (e: Throwable) {
                Log.e(TAG, "processImageFile error: ${e.message}")
                mainHandler.post { result.success(mapOf("hasFace" to false)) }
            }
        }
    }

    // ────────────────────────────────────────────────────────────────
    // Core detection
    // ────────────────────────────────────────────────────────────────
    private fun detectFace(landmarker: FaceLandmarker, bitmap: Bitmap): Map<String, Any?> {
        val mpImage = BitmapImageBuilder(bitmap).build()
        val faceResult = landmarker.detect(mpImage)

        if (faceResult.faceLandmarks().isEmpty()) {
            return mapOf("hasFace" to false)
        }

        val landmarks = faceResult.faceLandmarks()[0]
        val imgW = bitmap.width.toFloat()
        val imgH = bitmap.height.toFloat()

        // Map MediaPipe 478 landmarks → 10-point ML Kit format (pixel coords)
        val mapped = ArrayList<List<Double>>(LANDMARK_MAP.size)
        for (mpIdx in LANDMARK_MAP) {
            if (mpIdx < landmarks.size) {
                val lm = landmarks[mpIdx]
                mapped.add(listOf(
                    (lm.x() * imgW).toDouble(),
                    (lm.y() * imgH).toDouble()
                ))
            } else {
                mapped.add(listOf(Double.NaN, Double.NaN))
            }
        }

        // Bounding box from all landmarks
        var minX = Float.MAX_VALUE; var minY = Float.MAX_VALUE
        var maxX = -Float.MAX_VALUE; var maxY = -Float.MAX_VALUE
        for (lm in landmarks) {
            val px = lm.x() * imgW; val py = lm.y() * imgH
            if (px < minX) minX = px; if (py < minY) minY = py
            if (px > maxX) maxX = px; if (py > maxY) maxY = py
        }

        // Euler angles from 478 landmarks (more accurate than ML Kit's 10-point)
        val euler = computeEulerAngles(landmarks)

        return mapOf(
            "hasFace"     to true,
            "landmarks"   to mapped,
            "eulerAngleX" to euler.first,   // pitch
            "eulerAngleY" to euler.second,  // yaw
            "eulerAngleZ" to euler.third,   // roll
            "bbLeft"      to minX.toDouble(),
            "bbTop"       to minY.toDouble(),
            "bbWidth"     to (maxX - minX).toDouble(),
            "bbHeight"    to (maxY - minY).toDouble(),
            "imageWidth"  to imgW.toInt(),
            "imageHeight" to imgH.toInt()
        )
    }

    // ────────────────────────────────────────────────────────────────
    // Euler angles from 478 MediaPipe landmarks
    // ────────────────────────────────────────────────────────────────
    private fun computeEulerAngles(
        landmarks: List<com.google.mediapipe.tasks.components.containers.NormalizedLandmark>
    ): Triple<Double, Double, Double> {

        if (landmarks.size < 478) return Triple(0.0, 0.0, 0.0)

        // ── Pitch (head tilt forward/backward) ──
        // Ratio of forehead→nose vs nose→chin in normalized Y
        val forehead = landmarks[MP_FOREHEAD]
        val noseTip  = landmarks[MP_NOSE_TIP]
        val chin     = landmarks[MP_CHIN]

        val foreheadToNose = abs(noseTip.y() - forehead.y())
        val noseToChin     = abs(chin.y() - noseTip.y())
        val pitch = if (noseToChin > 0.001f) {
            Math.toDegrees(atan((foreheadToNose / noseToChin).toDouble()))
                .coerceIn(0.0, 90.0)
        } else 0.0

        // ── Yaw (head turn left/right) ──
        val leftEar  = landmarks[MP_LEFT_EAR]
        val rightEar = landmarks[MP_RIGHT_EAR]
        val faceWidth = abs(rightEar.x() - leftEar.x())
        val yaw = if (faceWidth > 0.001f) {
            val centerX = (leftEar.x() + rightEar.x()) / 2f
            val offset  = noseTip.x() - centerX
            ((offset / faceWidth) * 90.0).coerceIn(-45.0, 45.0)
        } else 0.0

        // ── Roll (head tilt sideways) ──
        val leftEye  = landmarks[MP_LEFT_EYE]
        val rightEye = landmarks[MP_RIGHT_EYE]
        val eyeDx = (rightEye.x() - leftEye.x()).toDouble()
        val eyeDy = (rightEye.y() - leftEye.y()).toDouble()
        val roll = if (abs(eyeDx) > 0.001) {
            Math.toDegrees(atan2(eyeDy, eyeDx)).coerceIn(-45.0, 45.0)
        } else 0.0

        return Triple(pitch, yaw, roll)
    }

    // ────────────────────────────────────────────────────────────────
    // Image conversion utilities
    // ────────────────────────────────────────────────────────────────

    /**
     * Convert Y-plane only (grayscale luminance) bytes to an ARGB_8888 Bitmap.
     * Works with ANY Camera2 YUV format since we only use the Y plane.
     */
    private fun yOnlyToBitmap(yData: ByteArray, width: Int, height: Int): Bitmap {
        val pixelCount = width * height
        val pixels = IntArray(pixelCount)
        val limit = min(pixelCount, yData.size)
        for (i in 0 until limit) {
            val y = yData[i].toInt() and 0xFF
            pixels[i] = (0xFF shl 24) or (y shl 16) or (y shl 8) or y
        }
        return Bitmap.createBitmap(pixels, width, height, Bitmap.Config.ARGB_8888)
    }

    private fun nv21ToBitmap(nv21: ByteArray, width: Int, height: Int): Bitmap {
        val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, width, height), 92, out)
        val jpegBytes = out.toByteArray()
        return BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)
    }

    private fun bgraToBitmap(bgra: ByteArray, width: Int, height: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        bitmap.copyPixelsFromBuffer(ByteBuffer.wrap(bgra))
        return bitmap
    }

    private fun rotateBitmap(bitmap: Bitmap, degrees: Float): Bitmap {
        if (degrees == 0f) return bitmap
        val matrix = Matrix()
        matrix.postRotate(degrees)
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    /**
     * Down-scale if the longest dimension exceeds [maxDim].
     * MediaPipe landmarks are normalized [0-1] so accuracy is preserved.
     */
    private fun maybeDownscale(bitmap: Bitmap, maxDim: Int): Bitmap {
        val longest = max(bitmap.width, bitmap.height)
        if (longest <= maxDim) return bitmap
        val scale = maxDim.toFloat() / longest
        return Bitmap.createScaledBitmap(
            bitmap,
            (bitmap.width * scale).toInt(),
            (bitmap.height * scale).toInt(),
            true
        )
    }

    // ────────────────────────────────────────────────────────────────
    // Cleanup
    // ────────────────────────────────────────────────────────────────
    private fun handleDispose(result: MethodChannel.Result) {
        faceLandmarker?.close()
        faceLandmarker = null
        result.success(true)
    }
}
