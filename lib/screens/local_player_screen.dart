import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import '../services/recording_manager.dart';
import 'dart:io';

class LocalPlayerScreen extends StatefulWidget {
  final String filePath;

  const LocalPlayerScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  State<LocalPlayerScreen> createState() => _LocalPlayerScreenState();
}

class _LocalPlayerScreenState extends State<LocalPlayerScreen> {
  late Player _player;
  late VideoController _controller;
  bool _isLoading = true;
  String? _error;
  double _playbackSpeed = 1.0;
  final List<double> _speedOptions = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 4.0];
  FocusNode? _focusNode;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _playFile();
  }

  Future<void> _takeSnapshot() async {
    try {
      // Obtener la carpeta de grabaciones
      final dir = await RecordingManager.getRecordingsFolder();
      
      // Generar nombre basado en el archivo original
      final originalName = widget.filePath.split(Platform.pathSeparator).last;
      // Extraer nombre de la cámara (si existe)
      String cameraName = 'captura';
      final match = RegExp(r'(Camara_[^_]+)').firstMatch(originalName);
      if (match != null) {
        cameraName = match.group(1)!;
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${dir.path}/${cameraName}_captura_$timestamp.jpg';
      
      // Capturar el frame actual
      final frame = await _player.screenshot();
      if (frame == null) {
        throw Exception('No se pudo capturar el fotograma');
      }
      
      // Guardar el archivo
      final file = File(outputPath);
      await file.writeAsBytes(frame);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Captura guardada: ${RecordingManager.getFriendlyName(outputPath)}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al capturar: $e')),
        );
      }
    }
  }

  // Método para cambiar velocidad:
  void _changeSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _player.setRate(speed);
  }

  Future<void> _playFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Convertir ruta para Windows
      String path = widget.filePath;
      if (Platform.isWindows) {
        path = path.replaceAll('\\', '/');
      }
      // Asegurar que la ruta comience con file:///
      if (!path.startsWith('file:///')) {
        path = 'file:///$path';
      }
      
      await _player.open(Media(path), play: true);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al reproducir: $e';
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reproduciendo grabación'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Botón de captura de fotograma
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _takeSnapshot,
            tooltip: 'Capturar fotograma',
          ),
          // Botón de velocidad
          PopupMenuButton<double>(
            icon: const Icon(Icons.speed),
            tooltip: 'Velocidad de reproducción',
            onSelected: _changeSpeed,
            itemBuilder: (context) => _speedOptions.map((speed) {
              return PopupMenuItem<double>(
                value: speed,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${speed}x'),
                    if (speed == _playbackSpeed)
                      const Icon(Icons.check, color: Colors.blue),
                  ],
                ),
              );
            }).toList(),
          ),
          // Mostrar velocidad actual
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                '${_playbackSpeed}x',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _playFile,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            : _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando video...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  )
                : Video(
                    controller: _controller,
                    fit: BoxFit.contain,
                  ),
      ),
    );
  }
}