package com.example.echo_alert

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.util.Log

class AudioForegroundService : Service() {

    fun interface AudioDataListener {
        fun onAudioDataCaptured(floats: FloatArray)
    }

    companion object {
        const val ACTION_START = "com.example.echo_alert.START_AUDIO"
        const val ACTION_STOP = "com.example.echo_alert.STOP_AUDIO"

        private const val CHANNEL_ID = "echo_alert_audio"
        private const val NOTIFICATION_ID = 1001
        private const val TAG = "EchoAlertAudio"
        private const val SAMPLE_RATE = 16000

        @Volatile
        var audioListener: AudioDataListener? = null

        @Volatile
        var isServiceRunning: Boolean = false
            private set
    }

    @Volatile
    private var isRecording = false

    private var audioRecord: AudioRecord? = null
    private var recordingThread: Thread? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {
        when (intent?.action) {
            ACTION_STOP -> stopAudioService()
            ACTION_START -> startAudioService()
        }

        return START_NOT_STICKY
    }

    private fun startAudioService() {
        if (isRecording) return

        try {
            createNotificationChannel()

            val notification = buildNotification()

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }

            val minBufferSize = AudioRecord.getMinBufferSize(
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )

            if (minBufferSize <= 0) {
                throw IllegalStateException(
                    "AudioRecord buffer configuration is unsupported"
                )
            }

            val bufferSize = maxOf(minBufferSize, 15600 * 2)

            val recorder = try {
                AudioRecord(
                    MediaRecorder.AudioSource.VOICE_RECOGNITION,
                    SAMPLE_RATE,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferSize
                )
            } catch (e: Exception) {
                AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    SAMPLE_RATE,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferSize
                )
            }

            if (recorder.state != AudioRecord.STATE_INITIALIZED) {
                recorder.release()
                throw IllegalStateException("AudioRecord initialization failed")
            }

            audioRecord = recorder
            recorder.startRecording()
            isRecording = true
            isServiceRunning = true

            recordingThread = Thread {
                captureAudio(recorder)
            }.apply {
                name = "EchoAlertAudioCapture"
                start()
            }

            Log.i(TAG, "Audio capture started successfully")

        } catch (exception: Exception) {
            Log.e(TAG, "Unable to start audio capture", exception)
            stopAudioService()
        }
    }

    private fun captureAudio(recorder: AudioRecord) {
        // YAMNet target chunk size: 15,600 mono PCM float samples @ 16 kHz (0.975 seconds)
        val readBuffer = ShortArray(1024)
        val accumulatedFloats = FloatArray(15600)
        var accumulatedCount = 0

        try {
            while (isRecording) {
                val readCount = recorder.read(
                    readBuffer,
                    0,
                    readBuffer.size,
                    AudioRecord.READ_BLOCKING
                )

                if (readCount > 0) {
                    for (i in 0 until readCount) {
                        accumulatedFloats[accumulatedCount++] = readBuffer[i] / 32768.0f
                        if (accumulatedCount == 15600) {
                            // Packet full (0.975 seconds of audio)
                            val packet = accumulatedFloats.clone()
                            accumulatedCount = 0
                            
                            // Calculate RMS volume level for logging
                            var sumSquares = 0.0
                            for (sample in packet) {
                                sumSquares += (sample * sample)
                            }
                            val rms = Math.sqrt(sumSquares / packet.size)
                            Log.d(TAG, "Captured 15600 audio samples (RMS level: ${String.format("%.4f", rms)})")
                            
                            audioListener?.onAudioDataCaptured(packet)
                        }
                    }
                } else if (readCount < 0) {
                    Log.e(TAG, "AudioRecord read error code: $readCount")
                    break
                }
            }
        } catch (exception: Exception) {
            Log.e(TAG, "Audio capture loop exception", exception)
        } finally {
            if (isRecording) {
                stopAudioService()
            }
        }
    }

    private fun stopAudioService() {
        isRecording = false
        isServiceRunning = false

        val recorder = audioRecord
        audioRecord = null

        if (recorder != null) {
            try {
                if (recorder.recordingState ==
                    AudioRecord.RECORDSTATE_RECORDING
                ) {
                    recorder.stop()
                }
            } catch (exception: Exception) {
                Log.w(TAG, "Error stopping recorder", exception)
            } finally {
                recorder.release()
            }
        }

        recordingThread = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "EchoAlert audio listening",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shown while EchoAlert listens for important sounds"
            }

            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val builder =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
            }

        return builder
            .setContentTitle("EchoAlert is listening")
            .setContentText("Microphone monitoring is active")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        isRecording = false
        isServiceRunning = false
        super.onDestroy()
        Log.i(TAG, "Audio service destroyed")
    }
}