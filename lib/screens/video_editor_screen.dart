import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/video_editor_service.dart';
import '../services/recording_manager.dart';
import 'local_player_screen.dart';

class VideoEditorScreen extends StatefulWidget {
  final String filePath;
  final String? cameraName;

  const VideoEditorScreen({
    Key? key,
    required this.filePath,
    this.cameraName,
  }) : super(key: key);

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  double _startSeconds = 0;
  double _endSeconds = 10;
  double _maxDuration = 10;
  bool _isLoading = true;
  bool _isProcessing = false;

  double _currentPosition = 0;
  Timer? _positionTimer;

  double _playbackSpeed = 1.0;
  final List<double> _speedOptions = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 4.0]; 
  
  // Reproductor para vista previa
  late Player _player;
  late VideoController _controller;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
   // Escuchar cambios de posición
    _player.stream.position.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position.inMilliseconds / 1000.0;
        });
      }
    });
    
    _loadDuration();
  }

  // Agregar método para alternar play/pause:
  void _togglePlayPause() {
    if (_player.state.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  Future<void> _loadDuration() async {
    try {
      print('📊 Cargando duración del video: ${widget.filePath}');
      final duration = await VideoEditorService.getVideoDuration(widget.filePath);
      print('📊 Duración obtenida: $duration segundos');
      
      setState(() {
        _maxDuration = duration;
        _endSeconds = duration > 10 ? 10 : duration;
        _isLoading = false;
      });
      // Cargar el video para vista previa
      await _loadVideo();
    } catch (e) {
      print('❌ Error al cargar duración: $e');
      setState(() {
        _maxDuration = 30; // Valor predeterminado
        _endSeconds = 10;
        _isLoading = false;
      });
      // Intentar cargar el video de todos modos
      await _loadVideo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No se pudo determinar la duración exacta, usando valor predeterminado'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadVideo() async {
    try {
      String path = widget.filePath;
      if (Platform.isWindows) {
        path = path.replaceAll('\\', '/');
      }
      if (!path.startsWith('file:///')) {
        path = 'file:///$path';
      }
      await _player.open(Media(path), play: true);
      setState(() => _isVideoReady = true);
    } catch (e) {
      print('Error al cargar video: $e');
    }
  }

  Future<void> _trimVideo() async {
    setState(() => _isProcessing = true);

    try {
      // trimVideo ya guarda en la carpeta correcta
      final outputPath = await VideoEditorService.trimVideo(
        widget.filePath,
        _startSeconds,
        _endSeconds,
        cameraName: widget.cameraName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Video recortado guardado: ${RecordingManager.getFriendlyName(outputPath)}')),
        );
        
        final play = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Video recortado'),
            content: const Text('¿Quieres reproducir el video recortado?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí'),
              ),
            ],
          ),
        );

        if (play == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LocalPlayerScreen(filePath: outputPath),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error al recortar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al recortar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _extractAudio() async {
    setState(() => _isProcessing = true);

    try {
      // extractAudio ya guarda en la carpeta correcta
      final outputPath = await VideoEditorService.extractAudio(
        widget.filePath,
        cameraName: widget.cameraName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Audio extraído: ${RecordingManager.getFriendlyName(outputPath)}')),
        );
      }
    } catch (e) {
      print('❌ Error al extraer audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al extraer audio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _formatTime(double seconds) {
    if (seconds.isNaN || seconds.isInfinite) return '00:00';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
        title: const Text('Editor de Video'),
        backgroundColor: Colors.black,
        actions: [
          if (_isVideoReady)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                _player.playOrPause();
              },
              tooltip: 'Play/Pause',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Vista previa del video (40% de la pantalla)
                Expanded(
                  flex: 4,
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      children: [
                        // Video
                        _isVideoReady
                            ? Video(
                                controller: _controller,
                                fit: BoxFit.contain,
                              )
                            : const Center(
                                child: Text(
                                  'Cargando video...',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                        // Controles overlay en la parte inferior
                        if (_isVideoReady)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Botón Play/Pause
                                  IconButton(
                                    icon: Icon(
                                      _player.state.playing ? Icons.pause : Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                    onPressed: _togglePlayPause,
                                    iconSize: 24,
                                  ),
                                  // Barra de progreso
                                  Expanded(
                                    child: Slider(
                                      value: _currentPosition.clamp(0, _maxDuration),
                                      min: 0,
                                      max: _maxDuration,
                                      onChanged: (value) {
                                        _player.seek(Duration(milliseconds: (value * 1000).toInt()));
                                      },
                                      activeColor: Colors.red,
                                      inactiveColor: Colors.white30,
                                    ),
                                  ),
                                  // Tiempo
                                  Text(
                                    '${_formatTime(_currentPosition)} / ${_formatTime(_maxDuration)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Controles de edición (60% de la pantalla)
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(  // <-- Agregar scroll
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información del archivo
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Archivo: ${RecordingManager.getFriendlyName(widget.filePath)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text('Duración total: ${_formatTime(_maxDuration)}'),
                                Text('Inicio: ${_formatTime(_startSeconds)} | Fin: ${_formatTime(_endSeconds)}'),
                                Text('Duración seleccionada: ${_formatTime(_endSeconds - _startSeconds)}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Selector de rango
                        const Text(
                          'Selecciona el rango a recortar:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        
                        // Slider inicio
                        Row(
                          children: [
                            const Text('Inicio', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Expanded(
                              child: Slider(
                                value: _startSeconds,
                                min: 0,
                                max: _maxDuration - 1,
                                onChanged: (value) {
                                  setState(() {
                                    _startSeconds = value;
                                    if (_startSeconds >= _endSeconds) {
                                      _endSeconds = (_startSeconds + 1).clamp(0, _maxDuration);
                                    }
                                  });
                                  // Actualizar posición del video
                                  _player.seek(Duration(milliseconds: (value * 1000).toInt()));
                                },
                              ),
                            ),
                            Text(
                              _formatTime(_startSeconds),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        
                        // Slider fin
                        Row(
                          children: [
                            const Text('Fin', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Expanded(
                              child: Slider(
                                value: _endSeconds,
                                min: 1,
                                max: _maxDuration,
                                onChanged: (value) {
                                  setState(() {
                                    _endSeconds = value;
                                    if (_endSeconds <= _startSeconds) {
                                      _startSeconds = (_endSeconds - 1).clamp(0, _maxDuration);
                                    }
                                  });
                                },
                              ),
                            ),
                            Text(
                              _formatTime(_endSeconds),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Botones de acción
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isProcessing ? null : _trimVideo,
                                icon: const Icon(Icons.content_cut),
                                label: const Text('Recortar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isProcessing ? null : _extractAudio,
                                icon: const Icon(Icons.audiotrack),
                                label: const Text('Extraer Audio'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        if (_isProcessing) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                          const SizedBox(height: 6),
                          const Center(
                            child: Text('Procesando... por favor espera'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}