import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class RecordingManager {
  static const String _prefix = 'recording_';
  static const String _extension = '.mp4';

  // Obtener la carpeta de grabaciones (crea V38n_Recordings en Descargas)
  static Future<Directory> getRecordingsFolder() async {
    final dir = await getDownloadsDirectory();
    if (dir == null) throw Exception('No se pudo acceder a Descargas');
    
    // Crear subcarpeta V38n_Recordings
    final recordingsDir = Directory('${dir.path}/V38n_Recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create();
      debugPrint('📁 Carpeta creada: ${recordingsDir.path}');
    }
    return recordingsDir;
  }

  // Guardar una grabación (mueve el archivo a la subcarpeta)
  static Future<String> saveRecording(
    String sourcePath, {
    String? cameraName,
    String? prefix,
  }) async {
    final dir = await getRecordingsFolder();
    final source = File(sourcePath);
    
    if (!await source.exists()) {
      print('⚠️ El archivo fuente no existe: $sourcePath');
      return sourcePath;
    }
    
    final sourceFileName = source.uri.pathSegments.last;
    
    // Si el archivo ya está en la carpeta correcta
    if (sourcePath.startsWith(dir.path)) {
      // Si es captura, solo verificar que esté en el lugar correcto
      if (sourceFileName.contains('captura')) {
        print('✅ Captura ya está en la carpeta correcta: $sourcePath');
        return sourcePath;
      }
      return sourcePath;
    }
    
    // Determinar extensión
    final extension = sourceFileName.contains('.jpg') ? '.jpg' : '.mp4';
    
    // Si el archivo está en otro lugar, moverlo
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    String baseName = prefix ?? 'recording';
    if (cameraName != null && cameraName.isNotEmpty) {
      final cleanName = cameraName.replaceAll(' ', '_');
      baseName = '${cleanName}_$baseName';
    }
    
    final fileName = '${baseName}_$timestamp$extension';
    final destPath = '${dir.path}/$fileName';
    
    if (await File(destPath).exists()) {
      await File(destPath).delete();
    }
    await source.rename(destPath);
    print('✅ Archivo movido a: $destPath');
    return destPath;
  }

  // Listar todas las grabaciones
  static Future<List<FileSystemEntity>> listRecordings() async {
    try {
      final dir = await getRecordingsFolder();
      if (!await dir.exists()) {
        print('📁 La carpeta V38n_Recordings no existe aún');
        return [];
      }
      
      final files = await dir.list().toList();
      print('📂 Archivos encontrados en V38n_Recordings: ${files.length}');
      
      // Filtrar archivos de video y audio
      final recordings = files.where((file) {
        final path = file.path.toLowerCase();
        // Aceptar archivos que contengan cualquiera de estos patrones
        return path.endsWith('.mp4') || 
              path.endsWith('.mp3') ||
              path.contains('grabacion') ||
              path.contains('recording') ||
              path.contains('recortado') ||
              path.contains('audio');
      }).toList();
      
      print('📂 Grabaciones filtradas: ${recordings.length}');
      
      // Ordenar por fecha de modificación (más reciente primero)
      recordings.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });
      
      return recordings;
    } catch (e) {
      print('❌ Error al listar grabaciones: $e');
      return [];
    }
  }

  // Eliminar una grabación
  static Future<void> deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      debugPrint('🗑️ Grabación eliminada: $path');
    }
  }

  // Obtener el nombre amigable de un archivo (fecha legible)
  static String getFriendlyName(String path) {
    final file = File(path);
    final name = file.uri.pathSegments.last;
    
    // Eliminar extensión
    final baseName = name.replaceAll(RegExp(r'\.[^.]+$'), '');
    
    // Caso 1: Formato con nombre de cámara: Camara_Frente_grabacion_1788181233957
    // o: Camara_Frente_recortado_1788181233957
    // o: Camara_Frente_audio_1788181233957.mp3
    final parts = baseName.split('_');
    
    // Buscar si la última parte es un número (timestamp)
    if (parts.isNotEmpty) {
      final lastPart = parts.last;
      if (int.tryParse(lastPart) != null && parts.length >= 3) {
        // Reconstruir nombre de la cámara y tipo
        final cameraName = parts.sublist(0, parts.length - 2).join(' ');
        final type = parts[parts.length - 2];
        
        // Obtener timestamp
        final timestamp = int.parse(lastPart);
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final timeStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        
        // Traducir tipo
        String typeLabel = '';
        switch (type) {
          case 'grabacion':
            typeLabel = '📹 Grabación';
            break;
          case 'recortado':
            typeLabel = '✂️ Recortado';
            break;
          case 'audio':
            typeLabel = '🎵 Audio';
            break;
          case 'recording':
            typeLabel = '📹 Grabación';
            break;
          case 'trimmed':
            typeLabel = '✂️ Recortado';
            break;
          case 'captura':
            typeLabel = '📸 Captura';
            break;
          default:
            typeLabel = type;
        }
        
        return '$typeLabel - $cameraName ($timeStr)';
      }
    }
    
    // Caso 2: Formato antiguo: recording_1788181233957.mp4
    final timestampStr = baseName
        .replaceAll('recording_', '')
        .replaceAll('trimmed_', '')
        .replaceAll('audio_', '')
        .replaceAll('grabacion_', '')
        .replaceAll('recortado_', '');
    
    if (timestampStr.isNotEmpty) {
      final timestamp = int.tryParse(timestampStr);
      if (timestamp != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    }
    
    // Caso 3: Si no se puede parsear, mostrar el nombre del archivo
    return name;
  }

  // Obtener tamaño del archivo en MB
  static String getFileSize(String path) {
    try {
      final file = File(path);
      final size = file.statSync().size;
      if (size < 1024 * 1024) {
        return '${(size / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return '0 KB';
    }
  }
}