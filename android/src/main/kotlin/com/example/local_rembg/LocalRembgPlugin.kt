package com.example.local_rembg

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import androidx.appcompat.app.AppCompatActivity
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.Segmentation
import com.google.mlkit.vision.segmentation.Segmenter
import com.google.mlkit.vision.segmentation.selfie.SelfieSegmenterOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

import android.renderscript.Allocation
import android.renderscript.Element
import android.renderscript.RenderScript
import android.renderscript.ScriptIntrinsicBlur

import android.os.Build
import android.content.Context
import android.graphics.HardwareRenderer
import android.graphics.PixelFormat
import android.graphics.RenderEffect
import android.graphics.RenderNode
import android.graphics.Shader
import android.hardware.HardwareBuffer
import android.media.ImageReader

class LocalRembgPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: AppCompatActivity? = null
    private lateinit var segmenter: Segmenter
    private var width = 0
    private var height = 0
    private var radius = 80f
    private var currentContext: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "methodChannel.localRembg")
        channel.setMethodCallHandler(this)
        currentContext = binding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val segmentOptions = SelfieSegmenterOptions.Builder()
            .setDetectorMode(SelfieSegmenterOptions.SINGLE_IMAGE_MODE)
            .build()
        segmenter = Segmentation.getClient(segmentOptions)

        when (call.method) {
            "removeBackground" -> {
                val arguments = call.arguments as? Map<*, *>
                val imageUint8List = arguments?.get("imageUint8List") as? ByteArray

                when {
                    imageUint8List != null -> removeBackgroundFromUint8List(
                        imageUint8List,
                        result
                    )

                    else -> sendErrorResult(result, 0, "Invalid arguments or unable to load image")
                }
            }

            "blurredBackground" -> {
                val arguments = call.arguments as? Map<*, *>
                val imageUint8List = arguments?.get("imageUint8List") as? ByteArray

                when {
                    imageUint8List != null -> removeBlurredBackgroundFromUint8List(
                        imageUint8List,
                        result
                    )

                    else -> sendErrorResult(result, 0, "Invalid arguments or unable to load image")
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun removeBackgroundFromUint8List(
        imageUint8List: ByteArray,
        result: MethodChannel.Result
    ) {
        val bitmap = BitmapFactory.decodeByteArray(imageUint8List, 0, imageUint8List.size)
        if (bitmap == null) {
            sendErrorResult(result, 0, "Failed to decode Uint8List image")
            return
        }

        processImage(bitmap, result)
    }

    private fun removeBlurredBackgroundFromUint8List(
        imageUint8List: ByteArray,
        result: MethodChannel.Result
    ) {
        val bitmap = BitmapFactory.decodeByteArray(imageUint8List, 0, imageUint8List.size)
        if (bitmap == null) {
            sendErrorResult(result, 0, "Failed to decode Uint8List image")
            return
        }

        processBlurredImage(bitmap, result)
    }

    private fun processImage(
        bitmap: Bitmap,
        result: MethodChannel.Result
    ) {
        val inputImage = InputImage.fromBitmap(bitmap, 0)
        segmenter.process(inputImage)
            .addOnSuccessListener { segmentationMask ->
                width = segmentationMask.width
                height = segmentationMask.height
                processSegmentationMask(result, bitmap, segmentationMask.buffer)
            }
            .addOnFailureListener { exception ->
                sendErrorResult(result, 0, exception.message ?: "Segmentation failed")
            }
    }

    private fun processBlurredImage(
        bitmap: Bitmap,
        result: MethodChannel.Result
    ) {
        val inputImage = InputImage.fromBitmap(bitmap, 0)
        segmenter.process(inputImage)
            .addOnSuccessListener { segmentationMask ->
                width = segmentationMask.width
                height = segmentationMask.height
                processBlurSegmentationMask(result, bitmap, segmentationMask.buffer)
            }
            .addOnFailureListener { exception ->
                sendErrorResult(result, 0, exception.message ?: "Segmentation failed")
            }
    }

    private fun processSegmentationMask(
        result: MethodChannel.Result,
        bitmap: Bitmap,
        buffer: ByteBuffer
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val bgConf = FloatArray(width * height)
                buffer.rewind()
                buffer.asFloatBuffer().get(bgConf)

                val newBmp = bitmap.copy(bitmap.config, true) ?: run {
                    sendErrorResult(result, 0, "Failed to copy bitmap")
                    return@launch
                }

                makeBackgroundTransparent(newBmp, bgConf)
                val resultBmp: Bitmap = newBmp

                val targetWidth = 1080
                val targetHeight =
                    (resultBmp.height.toFloat() / resultBmp.width.toFloat() * targetWidth).toInt()
                val resizedBmp =
                    Bitmap.createScaledBitmap(resultBmp, targetWidth, targetHeight, true)

                val processedBmp =
                    Bitmap.createBitmap(targetWidth, targetHeight, Bitmap.Config.ARGB_8888)
                Canvas(processedBmp).apply {
                    drawColor(Color.TRANSPARENT)
                    drawBitmap(
                        resizedBmp,
                        (targetWidth - resizedBmp.width) / 2f,
                        (targetHeight - resizedBmp.height) / 2f,
                        null
                    )
                }

                val outputStream = ByteArrayOutputStream()
                processedBmp.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                val processedImageBytes = outputStream.toByteArray()

                result.success(
                    mapOf(
                        "status" to 1,
                        "imageBytes" to processedImageBytes.toList(),
                        "message" to "Success"
                    )
                )
            } catch (e: Exception) {
                sendErrorResult(result, 0, e.message ?: "Error processing segmentation mask")
            }
        }
    }

    private fun processBlurSegmentationMask(
        result: MethodChannel.Result,
        bitmap: Bitmap,
        buffer: ByteBuffer
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val bgConf = FloatArray(width * height)
                buffer.rewind()
                buffer.asFloatBuffer().get(bgConf)

                val newBmp = bitmap.copy(bitmap.config, true) ?: run {
                    sendErrorResult(result, 0, "Failed to copy bitmap")
                    return@launch
                }

                val newBmp2 = bitmap.copy(bitmap.config, true) ?: run {
                    sendErrorResult(result, 0, "Failed to copy bitmap")
                    return@launch
                }

                val blurredBmp: Bitmap = blurBitmap(newBmp2, radius)
                makeBackgroundBlurred(newBmp, blurredBmp, bgConf)
                val resultBmp: Bitmap = newBmp

                val outputStream = ByteArrayOutputStream()
                resultBmp.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
                val processedImageBytes = outputStream.toByteArray()

                result.success(
                    mapOf(
                        "status" to 1,
                        "imageBytes" to processedImageBytes.toList(),
                        "message" to "Success"
                    )
                )
            } catch (e: Exception) {
                sendErrorResult(result, 0, e.message ?: "Error processing segmentation mask")
            }
        }
    }

    private fun makeBackgroundTransparent(bitmap: Bitmap, bgConf: FloatArray) {
        for (y in 0 until bitmap.height) {
            for (x in 0 until bitmap.width) {
                val index = y * bitmap.width + x
                val conf = (1.0f - bgConf[index]) * 255
                if (conf >= 100) {
                    bitmap.setPixel(x, y, Color.TRANSPARENT)
                }
            }
        }
    }

    private fun makeBackgroundBlurred(bitmap: Bitmap, blurredBmp: Bitmap, bgConf: FloatArray) {
        for (y in 0 until bitmap.height) {
            for (x in 0 until bitmap.width) {
                val index = y * bitmap.width + x
                val conf = (1.0f - bgConf[index]) * 255
                if (conf >= 100) {
                    bitmap.setPixel(x, y, blurredBmp.getPixel(x, y))
                }
            }
        }
    }

    private fun blurBitmap(bitmap: Bitmap, radius: Float): Bitmap {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return blurBitmapAPI31(bitmap, radius)
        }

        return blurBitmapBelowAPI31(bitmap, radius)
    }

    private fun blurBitmapAPI31(bitmap: Bitmap, radius: Float): Bitmap {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return bitmap;
        }

        val imageReader = ImageReader.newInstance(
            bitmap.width, bitmap.height,
            PixelFormat.RGBA_8888, 1,
            HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE or HardwareBuffer.USAGE_GPU_COLOR_OUTPUT
        )
        val renderNode = RenderNode("BlurEffect")
        val hardwareRenderer = HardwareRenderer()

        hardwareRenderer.setSurface(imageReader.surface)
        hardwareRenderer.setContentRoot(renderNode)
        renderNode.setPosition(0, 0, imageReader.width, imageReader.height)

        val blurRenderEffect = RenderEffect.createBlurEffect(
            radius, radius,
            Shader.TileMode.MIRROR
        )

        renderNode.setRenderEffect(blurRenderEffect)

        val renderCanvas = renderNode.beginRecording()

        renderCanvas.drawBitmap(bitmap, 0f, 0f, null)
        renderNode.endRecording()
        hardwareRenderer.createRenderRequest()
            .setWaitForPresent(true)
            .syncAndDraw()

        val image = imageReader.acquireNextImage() ?: throw RuntimeException("No Image")
        val hardwareBuffer = image.hardwareBuffer ?: throw RuntimeException("No HardwareBuffer")
        val newBmp = Bitmap.wrapHardwareBuffer(hardwareBuffer, null)
            ?: throw RuntimeException("Create Bitmap Failed")

        hardwareBuffer.close()
        image.close()
        imageReader.close()
        renderNode.discardDisplayList()
        hardwareRenderer.destroy()

        return newBmp.copy(Bitmap.Config.RGBA_F16, true)
    }

    private fun blurBitmapBelowAPI31(bitmap: Bitmap, radius: Float): Bitmap {
        val renderScript = RenderScript.create(currentContext)
        val input = Allocation.createFromBitmap(renderScript, bitmap)
        val output = Allocation.createTyped(renderScript, input.type)
        val scriptIntrinsicBlur =
            ScriptIntrinsicBlur.create(renderScript, Element.U8_4(renderScript))
        var blurRadius = radius

        if(radius > 25f) {
            blurRadius = 25f
        }

        scriptIntrinsicBlur.setRadius(blurRadius)
        scriptIntrinsicBlur.setInput(input)
        scriptIntrinsicBlur.forEach(output)
        output.copyTo(bitmap)

        renderScript.destroy()
        return bitmap
    }

    private fun sendErrorResult(result: MethodChannel.Result, status: Int, errorMessage: String?) {
        val errorResult = mapOf(
            "status" to status,
            "message" to errorMessage
        )
        result.success(errorResult)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as AppCompatActivity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as AppCompatActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }
}
