package com.example.echo_alert

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CONTROL_CHANNEL = "com.example.echo_alert/audio_control"
    private val STREAM_CHANNEL = "com.example.echo_alert/audio_stream"

    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTROL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    startAudioForegroundService()
                    result.success(true)
                }
                "stopListening" -> {
                    stopAudioForegroundService()
                    result.success(true)
                }
                "isListening" -> {
                    result.success(AudioForegroundService.isServiceRunning)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STREAM_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    AudioForegroundService.audioListener = AudioForegroundService.AudioDataListener { floats ->
                        runOnUiThread {
                            val floatList = floats.map { it.toDouble() }
                            eventSink?.success(floatList)
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    AudioForegroundService.audioListener = null
                }
            }
        )
    }

    private fun startAudioForegroundService() {
        val intent = Intent(this, AudioForegroundService::class.java).apply {
            action = AudioForegroundService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopAudioForegroundService() {
        val intent = Intent(this, AudioForegroundService::class.java).apply {
            action = AudioForegroundService.ACTION_STOP
        }
        startService(intent)
    }
}
