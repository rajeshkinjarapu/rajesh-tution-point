import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  int sampleRate = 44100;
  double duration = 0.65;
  int numSamples = (sampleRate * duration).toInt();
  
  Int16List buffer = Int16List(numSamples);
  
  for (int i = 0; i < numSamples; i++) {
    double t = i / sampleRate;
    double sample = 0;
    
    // Tone 1: Triangle, 880->1760 over 0.15s, gain 0.95->0.001 over 0.4s
    if (t <= 0.4) {
      double f0 = 880;
      double f1 = 1760;
      double T = 0.15;
      double phase;
      if (t <= T) {
        double k = log(f1/f0) / T;
        phase = (f0 / k) * (exp(k * t) - 1);
      } else {
        double k = log(f1/f0) / T;
        double phaseAtT = (f0 / k) * (exp(k * T) - 1);
        phase = phaseAtT + f1 * (t - T);
      }
      double vol = 0.95 * pow(0.001/0.95, t/0.4);
      double wave = 4 * ((phase % 1.0) - 0.5).abs() - 1;
      sample += wave * vol;
    }
    
    // Tone 2: Sine, 1318.51->2637 over 0.15s, gain 1.0->0.001 over 0.45s. Start 0.1s
    if (t >= 0.1 && t <= 0.55) {
      double t2 = t - 0.1;
      double f0 = 1318.51;
      double f1 = 2637;
      double T = 0.15;
      double phase;
      if (t2 <= T) {
        double k = log(f1/f0) / T;
        phase = (f0 / k) * (exp(k * t2) - 1);
      } else {
        double k = log(f1/f0) / T;
        double phaseAtT = (f0 / k) * (exp(k * T) - 1);
        phase = phaseAtT + f1 * (t2 - T);
      }
      double vol = 1.0 * pow(0.001/1.0, t2/0.45);
      double wave = sin(2 * pi * phase);
      sample += wave * vol;
    }
    
    // Tone 3: Triangle, 1760, gain 0.9->0.001 over 0.45s. Start 0.2s
    if (t >= 0.2 && t <= 0.65) {
      double t3 = t - 0.2;
      double f = 1760;
      double phase = f * t3;
      double vol = 0.9 * pow(0.001/0.9, t3/0.45);
      double wave = 4 * ((phase % 1.0) - 0.5).abs() - 1;
      sample += wave * vol;
    }
    
    sample = sample * 0.35; 
    if (sample > 1.0) sample = 1.0;
    if (sample < -1.0) sample = -1.0;
    
    buffer[i] = (sample * 32767).toInt();
  }
  
  int byteRate = sampleRate * 2;
  int blockAlign = 2;
  int subChunk2Size = numSamples * 2;
  int chunkSize = 36 + subChunk2Size;
  
  var file = File('android/app/src/main/res/raw/jy_notification.wav');
  file.parent.createSync(recursive: true);
  var sink = file.openSync(mode: FileMode.write);
  
  var header = ByteData(44);
  header.setUint8(0, 0x52); header.setUint8(1, 0x49); header.setUint8(2, 0x46); header.setUint8(3, 0x46);
  header.setUint32(4, chunkSize, Endian.little);
  header.setUint8(8, 0x57); header.setUint8(9, 0x41); header.setUint8(10, 0x56); header.setUint8(11, 0x45);
  header.setUint8(12, 0x66); header.setUint8(13, 0x6D); header.setUint8(14, 0x74); header.setUint8(15, 0x20);
  header.setUint32(16, 16, Endian.little); 
  header.setUint16(20, 1, Endian.little); 
  header.setUint16(22, 1, Endian.little); 
  header.setUint32(24, sampleRate, Endian.little); 
  header.setUint32(28, byteRate, Endian.little); 
  header.setUint16(32, blockAlign, Endian.little); 
  header.setUint16(34, 16, Endian.little); 
  header.setUint8(36, 0x64); header.setUint8(37, 0x61); header.setUint8(38, 0x74); header.setUint8(39, 0x61);
  header.setUint32(40, subChunk2Size, Endian.little);
  
  sink.writeFromSync(header.buffer.asUint8List());
  sink.writeFromSync(buffer.buffer.asUint8List());
  sink.closeSync();
  print('Generated jy_notification.wav for Android');
  
  var iosFile = File('ios/Runner/jy_notification.wav');
  iosFile.parent.createSync(recursive: true);
  var iosSink = iosFile.openSync(mode: FileMode.write);
  iosSink.writeFromSync(header.buffer.asUint8List());
  iosSink.writeFromSync(buffer.buffer.asUint8List());
  iosSink.closeSync();
  print('Generated jy_notification.wav for iOS');
}
