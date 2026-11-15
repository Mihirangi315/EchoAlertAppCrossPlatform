import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Member E: Demo Test Audio Generator
/// Synthesizes 16kHz, 16-bit Mono PCM WAV audio samples for all 5 target categories:
/// - Doorbell (Dual-tone ding-dong chime)
/// - Smoke / Fire Alarm (3kHz pulsing warning tone)
/// - Baby Crying (Modulated vocal crying tone)
/// - Phone Ringing (US dual-tone 440+480Hz cadence)
/// - Door Knocking (Percussive acoustic thumps)

void main() {
  final outputDir = Directory('assets/audio_samples');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  print('Generating test audio demonstration samples in ${outputDir.path}...');

  // 1. Doorbell
  final doorbellSamples = generateDoorbell(16000);
  writeWavFile('${outputDir.path}/doorbell.wav', doorbellSamples, 16000);

  // 2. Smoke Alarm
  final alarmSamples = generateSmokeAlarm(16000);
  writeWavFile('${outputDir.path}/alarm.wav', alarmSamples, 16000);

  // 3. Baby Crying
  final babyCrySamples = generateBabyCry(16000);
  writeWavFile('${outputDir.path}/baby_cry.wav', babyCrySamples, 16000);

  // 4. Phone Ringing
  final phoneSamples = generatePhoneRinging(16000);
  writeWavFile('${outputDir.path}/phone_ringing.wav', phoneSamples, 16000);

  // 5. Door Knocking
  final knockSamples = generateDoorKnocking(16000);
  writeWavFile('${outputDir.path}/door_knocking.wav', knockSamples, 16000);

  print('✅ Successfully generated all 5 demo WAV audio samples!');
}

/// Generates a two-tone "Ding-Dong" chime (G5 784Hz -> E5 659Hz)
List<double> generateDoorbell(int sampleRate) {
  final samples = <double>[];
  final dingDuration = 0.7; // seconds
  final dongDuration = 1.0; // seconds

  // Tone 1: 784 Hz (Ding)
  final dingSamples = (dingDuration * sampleRate).toInt();
  for (int i = 0; i < dingSamples; i++) {
    final t = i / sampleRate;
    final decay = math.exp(-3.5 * t);
    final val = math.sin(2 * math.pi * 784.0 * t) * decay * 0.75;
    samples.add(val);
  }

  // Tone 2: 659 Hz (Dong)
  final dongSamples = (dongDuration * sampleRate).toInt();
  for (int i = 0; i < dongSamples; i++) {
    final t = i / sampleRate;
    final decay = math.exp(-2.5 * t);
    final val = math.sin(2 * math.pi * 659.25 * t) * decay * 0.85;
    samples.add(val);
  }

  return samples;
}

/// Generates a standard high-frequency smoke alarm (3000 Hz pulsing beep)
List<double> generateSmokeAlarm(int sampleRate) {
  final samples = <double>[];
  final pulseDuration = 0.45;
  final silenceDuration = 0.15;

  for (int p = 0; p < 4; p++) {
    final pulseCount = (pulseDuration * sampleRate).toInt();
    for (int i = 0; i < pulseCount; i++) {
      final t = i / sampleRate;
      final val = math.sin(2 * math.pi * 3100.0 * t) * 0.90;
      samples.add(val);
    }

    final silenceCount = (silenceDuration * sampleRate).toInt();
    for (int i = 0; i < silenceCount; i++) {
      samples.add(0.0);
    }
  }

  return samples;
}

/// Generates a modulated vocal frequency mimicking baby cry wails (450-550 Hz)
List<double> generateBabyCry(int sampleRate) {
  final samples = <double>[];
  final totalDuration = 2.5;
  final totalCount = (totalDuration * sampleRate).toInt();

  for (int i = 0; i < totalCount; i++) {
    final t = i / sampleRate;
    // Pitch modulation: 500 Hz +/- 80 Hz vibrato at 3.5 Hz
    final modFreq = 500.0 + 80.0 * math.sin(2 * math.pi * 3.5 * t);
    // Amplitude modulation mimicking breathing wails
    final ampMod = 0.5 + 0.45 * math.sin(2 * math.pi * 1.8 * t);
    final val = math.sin(2 * math.pi * modFreq * t) * ampMod * 0.75;
    samples.add(val);
  }

  return samples;
}

/// Generates standard phone ringing dual-tone cadence (440 Hz + 480 Hz)
List<double> generatePhoneRinging(int sampleRate) {
  final samples = <double>[];
  final ringDuration = 1.6;
  final pauseDuration = 1.0;

  for (int ring = 0; ring < 2; ring++) {
    final ringCount = (ringDuration * sampleRate).toInt();
    for (int i = 0; i < ringCount; i++) {
      final t = i / sampleRate;
      final tone1 = math.sin(2 * math.pi * 440.0 * t);
      final tone2 = math.sin(2 * math.pi * 480.0 * t);
      samples.add((tone1 + tone2) * 0.40);
    }

    final pauseCount = (pauseDuration * sampleRate).toInt();
    for (int i = 0; i < pauseCount; i++) {
      samples.add(0.0);
    }
  }

  return samples;
}

/// Generates 3 acoustic percussive knocks with resonant wooden decay
List<double> generateDoorKnocking(int sampleRate) {
  final samples = <double>[];
  final random = math.Random(42);

  for (int knock = 0; knock < 3; knock++) {
    final knockDuration = 0.18;
    final knockCount = (knockDuration * sampleRate).toInt();

    for (int i = 0; i < knockCount; i++) {
      final t = i / sampleRate;
      final decay = math.exp(-32.0 * t);
      // Low resonant thud (120 Hz) + sharp transient noise burst
      final lowThump = math.sin(2 * math.pi * 120.0 * t) * 0.7;
      final noise = (random.nextDouble() * 2.0 - 1.0) * 0.4;
      samples.add((lowThump + noise) * decay * 0.95);
    }

    // Silence between knocks (0.22 seconds)
    final gapCount = (0.22 * sampleRate).toInt();
    for (int i = 0; i < gapCount; i++) {
      samples.add(0.0);
    }
  }

  return samples;
}

/// Writes mono 16-bit PCM WAV file format with RIFF header
void writeWavFile(String path, List<double> floatSamples, int sampleRate) {
  final numSamples = floatSamples.length;
  final bytesPerSample = 2; // 16-bit PCM
  final subChunk2Size = numSamples * bytesPerSample;
  final chunkSize = 36 + subChunk2Size;

  final byteData = ByteData(44 + subChunk2Size);

  // RIFF header
  _writeString(byteData, 0, 'RIFF');
  byteData.setUint32(4, chunkSize, Endian.little);
  _writeString(byteData, 8, 'WAVE');

  // fmt subchunk
  _writeString(byteData, 12, 'fmt ');
  byteData.setUint32(16, 16, Endian.little); // SubChunk1Size (16 for PCM)
  byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
  byteData.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
  byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
  byteData.setUint32(
    28,
    sampleRate * bytesPerSample,
    Endian.little,
  ); // ByteRate
  byteData.setUint16(32, bytesPerSample, Endian.little); // BlockAlign
  byteData.setUint16(34, 16, Endian.little); // BitsPerSample

  // data subchunk
  _writeString(byteData, 36, 'data');
  byteData.setUint32(40, subChunk2Size, Endian.little);

  // Sample data (convert float [-1.0, 1.0] to int16 [-32768, 32767])
  int offset = 44;
  for (int i = 0; i < numSamples; i++) {
    final clamped = floatSamples[i].clamp(-1.0, 1.0);
    final int16Val = (clamped * 32767.0).toInt();
    byteData.setInt16(offset, int16Val, Endian.little);
    offset += 2;
  }

  File(path).writeAsBytesSync(byteData.buffer.asUint8List());
  print(
    'Generated WAV: $path (${(File(path).lengthSync() / 1024).toStringAsFixed(1)} KB)',
  );
}

void _writeString(ByteData byteData, int offset, String s) {
  for (int i = 0; i < s.length; i++) {
    byteData.setUint8(offset + i, s.codeUnitAt(i));
  }
}
