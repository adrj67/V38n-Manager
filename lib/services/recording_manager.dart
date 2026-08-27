import 'dart:io';
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
      print('📁 Carpeta creada: ${recordingsDir.path}');
    }
    return recordingsDir;
  }

  // Guardar una grabación (mueve el archivo a la subcarpeta)
  static Future<String> saveRecording(String sourcePath) async {
    final dir = await getRecordingsFolder();
    final fileName = File(sourcePath).uri.pathSegments.last;
    final destPath = '${dir.path}/$fileName';
    
    final source = File(sourcePath);
    if (await source.exists()) {
      // Si ya existe en el destino, lo eliminamos
      final dest = File(destPath);
      if (await dest.exists()) {
        await dest.delete();
      }
      // Movemos el archivo
      await source.rename(destPath);
      print('✅ Grabación movida a: $destPath');
      return destPath;
    }
    return sourcePath;
  }

  // Listar todas las grabaciones
  static Future<List<FileSystemEntity>> listRecordings() async {
    try {
      final dir = await getRecordingsFolder();
      final files = await dir.list().toList();
      return files
          .where((file) =>
              file.path.endsWith(_extension) &&
              file.path.contains(_prefix))
          .toList()
        ..sort((a, b) {
          // Ordenar por fecha de modificación (más reciente primero)
          final aStat = a.statSync();
          final bStat = b.statSync();
          return bStat.modified.compareTo(aStat.modified);
        });
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
      print('🗑️ Grabación eliminada: $path');
    }
  }

  // Obtener el nombre amigable de un archivo (fecha legible)
  static String getFriendlyName(String path) {
  final file = File(path);
  final name = file.uri.pathSegments.last;
  
  try {
    // Extraer timestamp: recording_1787836504031.mp4
    final timestampStr = name
        .replaceAll(_prefix, '')
        .replaceAll(_extension, '');
    
    // Asegurar que es un número válido
    final timestamp = int.tryParse(timestampStr);
    if (timestamp == null) return name;
    
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    // Formato: 27/08/2026 10:15:29
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  } catch (e) {
    print('❌ Error al parsear nombre: $e');
    return name;
  }
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