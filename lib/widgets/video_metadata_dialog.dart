import 'package:flutter/material.dart';
import 'dart:io';
import '../services/video_editor_service.dart';
import '../services/recording_manager.dart';

class VideoMetadataDialog extends StatelessWidget {
  final String filePath;

  const VideoMetadataDialog({Key? key, required this.filePath}) : super(key: key);

  static Future<void> show(BuildContext context, String filePath) async {
    return showDialog(
      context: context,
      builder: (context) => VideoMetadataDialog(filePath: filePath),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final name = RecordingManager.getFriendlyName(filePath);
    final size = RecordingManager.getFileSize(filePath);
    final modified = file.statSync().modified;

    return FutureBuilder<double>(
      future: VideoEditorService.getVideoDuration(filePath),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? 0;

        return AlertDialog(
          title: const Text('Información del video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Nombre', name),
              const Divider(),
              _infoRow('Tamaño', size),
              const Divider(),
              _infoRow('Duración', _formatDuration(duration)),
              const Divider(),
              _infoRow('Modificado', 
                '${modified.day}/${modified.month}/${modified.year} ${modified.hour}:${modified.minute.toString().padLeft(2, '0')}'),
              const Divider(),
              _infoRow('Tipo', filePath.endsWith('.mp3') ? '🎵 Audio' : '🎬 Video'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return 'Desconocida';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs.toInt()}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs.toInt()}s';
    } else {
      return '${secs.toInt()}s';
    }
  }
}