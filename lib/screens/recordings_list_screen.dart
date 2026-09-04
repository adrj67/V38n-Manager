import 'package:flutter/material.dart';
import 'package:v38n_manager/widgets/video_metadata_dialog.dart';
import 'dart:io';
import '../services/recording_manager.dart';
import '../services/video_editor_service.dart';
import 'local_player_screen.dart';
import 'video_editor_screen.dart';

class RecordingsListScreen extends StatefulWidget {
  const RecordingsListScreen({Key? key}) : super(key: key);

  @override
  State<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends State<RecordingsListScreen> {
  List<FileSystemEntity> _recordings = [];
  List<FileSystemEntity> _editedFiles = [];
  bool _isLoading = true;
  bool _showOriginal = true;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    setState(() => _isLoading = true);
    try {
      print('🔄 Cargando grabaciones...');
      final allFiles = await RecordingManager.listRecordings();
      print('📂 Total de archivos encontrados: ${allFiles.length}');
      
      // Mostrar nombres de archivos para depuración
      for (final file in allFiles) {
        print('  - ${file.path.split(Platform.pathSeparator).last}');
      }
      
      // Separar originales y editados
      final originals = <FileSystemEntity>[];
      final edited = <FileSystemEntity>[];
      
      for (final file in allFiles) {
        final fileName = file.path.split(Platform.pathSeparator).last.toLowerCase();
        // Archivos editados: contienen 'recortado', 'audio', o 'captura'
        if (fileName.contains('recortado') || 
            fileName.contains('audio') || 
            fileName.contains('trimmed') ||
            fileName.contains('captura')) {  // <-- Agregar captura
          edited.add(file);
        } else {
          originals.add(file);
        }
      }
      
      print('📹 Originales: ${originals.length}');
      print('✂️ Editados: ${edited.length}');
      
      setState(() {
        _recordings = originals;
        _editedFiles = edited;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar grabaciones: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: $e')),
        );
      }
    }
  }

  Future<void> _deleteRecording(String path) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar grabación'),
        content: const Text('¿Estás seguro?'),
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
        _loadRecordings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
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

  // Extrae nombre de la cámara - retorna null si no lo encuentra
  String? _extractCameraName(String filePath) {  // <-- Cambiar a String?
    final fileName = filePath.split(Platform.pathSeparator).last;
    // Buscar "Camara_Frente" en el nombre del archivo
    final match = RegExp(r'(Camara_[^_]+)').firstMatch(fileName);
    if (match != null) {
      return match.group(1)!.replaceAll('_', ' ');
    }
    return null;  // <-- Ahora es válido porque String? permite null
  }

  //  _editRecording
  void _editRecording(String path) {
    final cameraName = _extractCameraName(path);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoEditorScreen(
          filePath: path,
          cameraName: cameraName,  // <-- Ahora puede ser null
        ),
      ),
    ).then((_) => _loadRecordings());
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
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Panel izquierdo: Originales
                Expanded(
                  child: _buildPanel(
                    '📹 Originales',
                    _recordings,
                    Colors.blue,
                    showEditButton: true,
                  ),
                ),
                // Panel derecho: Editados
                Expanded(
                  child: _buildPanel(
                    '✂️ Editados',
                    _editedFiles,
                    Colors.orange,
                    showEditButton: false,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPanel(String title, List<FileSystemEntity> files, Color color,
      {bool showEditButton = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.folder, color: color),
                const SizedBox(width: 8),
                Text(
                  '$title (${files.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: files.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'Sin archivos',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final path = file.path;
                      final name = RecordingManager.getFriendlyName(path);
                      final size = RecordingManager.getFileSize(path);
                      
                      // Determinar si es audio o video
                      final isAudio = path.endsWith('.mp3');
                      final icon = isAudio ? Icons.audiotrack : Icons.video_file;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: ListTile(
                          leading: Icon(icon, color: color),
                          title: Text(
                            name,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            size,
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showEditButton && !isAudio)
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _editRecording(path),
                                  tooltip: 'Editar',
                                  iconSize: 20,
                                ),
                              IconButton(
                                icon: const Icon(Icons.play_arrow, color: Colors.green),
                                onPressed: () => _playRecording(path),
                                tooltip: 'Reproducir',
                                iconSize: 20,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteRecording(path),
                                tooltip: 'Eliminar',
                                iconSize: 20,
                              ),
                              IconButton(
                                icon: const Icon(Icons.info, color: Colors.blue),
                                onPressed: () => VideoMetadataDialog.show(context, path),
                                tooltip: 'Información',
                                iconSize: 20,
                              ),
                            ],
                          ),
                          onTap: () => _playRecording(path),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}