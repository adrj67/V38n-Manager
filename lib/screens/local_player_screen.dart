import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
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

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _playFile();
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