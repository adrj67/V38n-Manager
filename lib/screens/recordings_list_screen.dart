import 'package:flutter/material.dart';
import 'dart:io';
import '../services/recording_manager.dart';
import 'local_player_screen.dart';

class RecordingsListScreen extends StatefulWidget {
  const RecordingsListScreen({Key? key}) : super(key: key);

  @override
  State<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends State<RecordingsListScreen> {
  List<FileSystemEntity> _recordings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    setState(() => _isLoading = true);
    try {
      final files = await RecordingManager.listRecordings();
      setState(() {
        _recordings = files;
        _isLoading = false;
      });
      print('📂 Grabaciones cargadas: ${files.length}');
    } catch (e) {
      print('❌ Error al cargar grabaciones: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar grabaciones: $e')),
        );
      }
    }
  }

  Future<void> _deleteRecording(String path) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar grabación'),
        content: const Text('¿Estás seguro de que quieres eliminar este archivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await RecordingManager.deleteRecording(path);
        _loadRecordings(); // Recargar lista
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Grabación eliminada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  void _playRecording(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocalPlayerScreen(filePath: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Grabaciones'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecordings,
            tooltip: 'Recargar lista',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recordings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay grabaciones',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Graba desde la pantalla de la cámara',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _recordings.length,
                  itemBuilder: (context, index) {
                    final file = _recordings[index];
                    final path = file.path;
                    final name = RecordingManager.getFriendlyName(path);
                    final size = RecordingManager.getFileSize(path);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.video_file, color: Colors.blue),
                        title: Text(name),
                        subtitle: Text('Tamaño: $size'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow, color: Colors.green),
                              onPressed: () => _playRecording(path),
                              tooltip: 'Reproducir',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRecording(path),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                        onTap: () => _playRecording(path),
                      ),
                    );
                  },
                ),
    );
  }
}