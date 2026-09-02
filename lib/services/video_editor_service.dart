import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:v38n_manager/services/recording_manager.dart';

class VideoEditorService {
  // Recortar un video desde un punto de inicio hasta un punto final (en segundos)
  static Future<String> trimVideo(
    String inputPath,
    double startSeconds,
    double endSeconds, {
    String? cameraName,
  }) async {
    final dir = await RecordingManager.getRecordingsFolder();
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Construir nombre con cámara
    String baseName = 'recortado';
    if (cameraName != null && cameraName.isNotEmpty) {
      // Limpiar el nombre (reemplazar espacios y caracteres especiales)
      final cleanName = cameraName
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      baseName = '${cleanName}_recortado';
      print('📝 Nombre con cámara: $baseName');
    } else {
      print('⚠️ No se proporcionó nombre de cámara');
    }
    
    final outputPath = '${dir.path}/${baseName}_$timestamp.mp4';
    print('📝 Ruta de salida: $outputPath');
    
    // Calcular duración
    final duration = endSeconds - startSeconds;
    if (duration <= 0) {
      throw Exception('La duración debe ser mayor a 0 segundos');
    }

    String ffmpegPath = await _getFfmpegPath();

    final args = [
      '-i', inputPath,
      '-ss', startSeconds.toString(),
      '-t', duration.toString(),
      '-c:v', 'copy',
      '-c:a', 'aac',
      '-b:a', '64k',
      '-y',
      outputPath,
    ];

    print('🎬 Recortando video: ${args.join(' ')}');
    
    final result = await Process.run(ffmpegPath, args);
    if (result.exitCode != 0) {
      throw Exception('FFmpeg error: ${result.stderr}');
    }

    print('✅ Video recortado guardado en: $outputPath');
    return outputPath;
  }

  // Extraer audio de un video
  static Future<String> extractAudio(
    String inputPath, {
    String? cameraName,
  }) async {
    final dir = await RecordingManager.getRecordingsFolder();
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Construir nombre con cámara
    String baseName = 'audio';
    if (cameraName != null && cameraName.isNotEmpty) {
      final cleanName = cameraName
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      baseName = '${cleanName}_audio';
      print('📝 Nombre con cámara: $baseName');
    } else {
      print('⚠️ No se proporcionó nombre de cámara');
    }
    
    final outputPath = '${dir.path}/${baseName}_$timestamp.mp3';
    print('📝 Ruta de salida: $outputPath');

    String ffmpegPath = await _getFfmpegPath();

    final args = [
      '-i', inputPath,
      '-vn',
      '-acodec', 'mp3',
      '-ab', '128k',
      '-y',
      outputPath,
    ];

    print('🎵 Extrayendo audio: ${args.join(' ')}');
    
    final result = await Process.run(ffmpegPath, args);
    if (result.exitCode != 0) {
      throw Exception('FFmpeg error: ${result.stderr}');
    }

    print('✅ Audio extraído en: $outputPath');
    return outputPath;
  }

  // Obtener duración del video en segundos
  static Future<double> getVideoDuration(String inputPath) async {
    String ffmpegPath = await _getFfmpegPath();

    // Método 1: Usar ffprobe (más confiable)
    try {
      // Intentar con ffprobe primero
      final ffprobeArgs = [
        '-v', 'quiet',
        '-print_format', 'json',
        '-show_streams',
        '-show_format',
        inputPath,
      ];
      
      // Buscar ffprobe en el mismo directorio que ffmpeg
      String ffprobePath = ffmpegPath.replaceAll('ffmpeg.exe', 'ffprobe.exe');
      if (!await File(ffprobePath).exists()) {
        ffprobePath = 'ffprobe';
      }
      
      final result = await Process.run(ffprobePath, ffprobeArgs);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        // Buscar "duration" en el JSON
        final durationMatch = RegExp(r'"duration"\s*:\s*"([^"]+)"').firstMatch(output);
        if (durationMatch != null) {
          final duration = double.tryParse(durationMatch.group(1)!);
          if (duration != null && duration > 0) {
            return duration;
          }
        }
      }
    } catch (e) {
      print('ffprobe falló, intentando con ffmpeg: $e');
    }

    // Método 2: Usar ffmpeg como fallback
    try {
      final args = [
        '-i', inputPath,
        '-show_entries', 'format=duration',
        '-v', 'quiet',
        '-of', 'csv=p=0',
      ];

      final result = await Process.run(ffmpegPath, args);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final duration = double.tryParse(output.trim());
        if (duration != null && duration > 0) {
          return duration;
        }
      }
    } catch (e) {
      print('ffmpeg falló: $e');
    }

    // Método 3: Intentar extraer de la salida de ffmpeg
    try {
      final args = ['-i', inputPath];
      final result = await Process.run(ffmpegPath, args, runInShell: true);
      final output = result.stderr as String;
      
      // Buscar "Duration: 00:00:10.00" en la salida
      final durationMatch = RegExp(r'Duration:\s*(\d{2}):(\d{2}):(\d{2}\.\d+)').firstMatch(output);
      if (durationMatch != null) {
        final hours = int.parse(durationMatch.group(1)!);
        final minutes = int.parse(durationMatch.group(2)!);
        final seconds = double.parse(durationMatch.group(3)!);
        return hours * 3600 + minutes * 60 + seconds;
      }
    } catch (e) {
      print('Extracción de duración falló: $e');
    }

    // Si todo falla, devolver un valor predeterminado
    print('⚠️ No se pudo obtener la duración, usando valor predeterminado de 30 segundos');
    return 30.0;
  }

  static Future<String> _getFfmpegPath() async {
    if (Platform.isWindows) {
      try {
        final whichResult = await Process.run('where', ['ffmpeg']);
        if (whichResult.exitCode == 0) {
          return (whichResult.stdout as String).trim().split('\n').first;
        }
        final commonPaths = [
          'C:/ffmpeg/bin/ffmpeg.exe',
          'C:/Program Files/ffmpeg/bin/ffmpeg.exe',
        ];
        for (final path in commonPaths) {
          if (await File(path).exists()) {
            return path;
          }
        }
      } catch (e) {}
    }
    return 'ffmpeg';
  }
}