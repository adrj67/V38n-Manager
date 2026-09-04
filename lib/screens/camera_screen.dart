import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:v38n_manager/screens/recordings_list_screen.dart';
import '../core/config/camera_config.dart';
import '../widgets/rtsp_player.dart';
import '../services/recording_manager.dart';
import '../widgets/duration_selector.dart';
import 'local_player_screen.dart';

class CameraScreen extends StatefulWidget {
  final CameraConfig camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isRecording = false;
  String? _lastRecordedFile;
  int _selectedDuration = 30; // Duración predeterminada
  int _recordingCountdown = 0;
  Timer? _countdownTimer;

  Future<void> _startRecording() async {
    if (_isRecording) return;

    setState(() {
      _isRecording = true;
      _recordingCountdown = _selectedDuration;
    });

    // Iniciar cuenta regresiva
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingCountdown--;
      });
      if (_recordingCountdown <= 0) {
        timer.cancel();
      }
    });

    try {
      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception('No se pudo acceder a Descargas');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${dir.path}/recording_$timestamp.mp4';

      await _recordWithFFmpeg(
        widget.camera.rtspUrl,
        tempPath,
        duration: _selectedDuration,
      );

      final finalPath = await RecordingManager.saveRecording(
        tempPath,
        cameraName: widget.camera.name,
        prefix: 'grabacion',
      );

      setState(() {
        _lastRecordedFile = finalPath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Grabación de ${_selectedDuration}s guardada'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al grabar: $e')),
        );
      }
    } finally {
      _countdownTimer?.cancel();
      if (mounted) setState(() {
        _isRecording = false;
        _recordingCountdown = 0;
      });
    }
  }

  Future<void> _recordWithFFmpeg(String rtspUrl, String outputPath,
      {int duration = 30}) async {
    String ffmpegPath = 'ffmpeg';
    if (Platform.isWindows) {
      try {
        final whichResult = await Process.run('where', ['ffmpeg']);
        if (whichResult.exitCode == 0) {
          ffmpegPath = (whichResult.stdout as String).trim().split('\n').first;
        } else {
          final commonPaths = [
            'C:/ffmpeg/bin/ffmpeg.exe',
            'C:/Program Files/ffmpeg/bin/ffmpeg.exe',
          ];
          for (final path in commonPaths) {
            if (await File(path).exists()) {
              ffmpegPath = path;
              break;
            }
          }
        }
      } catch (e) {}
    }

    final args = [
      '-i', rtspUrl,
      '-c:v', 'copy',
      '-c:a', 'aac',
      '-b:a', '64k',
      '-t', duration.toString(),
      '-y',
      outputPath,
    ];

    final result = await Process.run(ffmpegPath, args);
    if (result.exitCode != 0) {
      throw Exception('FFmpeg error: ${result.stderr}');
    }
  }

  void _playRecording() {
    if (_lastRecordedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocalPlayerScreen(filePath: _lastRecordedFile!),
        ),
      );
    }
  }

  void _openDownloadsFolder() async {
    try {
      // Obtener la ruta de Descargas correcta en Windows
      String downloadsPath;
      if (Platform.isWindows) {
        // Usar la variable de entorno USERPROFILE
        final userProfile = Platform.environment['USERPROFILE'] ?? '';
        downloadsPath = '$userProfile\\Downloads\\V38n_Recordings';
      } else {
        final dir = await RecordingManager.getRecordingsFolder();
        downloadsPath = dir.path;
      }
      
      final dir = Directory(downloadsPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      if (Platform.isWindows) {
        await Process.run('explorer', [downloadsPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [downloadsPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [downloadsPath]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir carpeta: $e')),
        );
      }
    }
  }

  // método para capturar fotograma:
  Future<void> _takeSnapshot() async {
    try {
      // Usar la carpeta de grabaciones en lugar de Descargas
      final dir = await RecordingManager.getRecordingsFolder();
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanName = widget.camera.name.replaceAll(' ', '_');
      final outputPath = '${dir.path}/${cleanName}_captura_$timestamp.jpg';

      String ffmpegPath = 'ffmpeg';
      if (Platform.isWindows) {
        try {
          final whichResult = await Process.run('where', ['ffmpeg']);
          if (whichResult.exitCode == 0) {
            ffmpegPath = (whichResult.stdout as String).trim().split('\n').first;
          }
        } catch (e) {}
      }

      final args = [
        '-i', widget.camera.rtspUrl,
        '-frames:v', '1',
        '-q:v', '2',
        '-y',
        outputPath,
      ];

      final result = await Process.run(ffmpegPath, args);
      if (result.exitCode != 0) {
        throw Exception('Error al capturar: ${result.stderr}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Captura guardada: ${RecordingManager.getFriendlyName(outputPath)}')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.camera.name),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: RtspPlayer(url: widget.camera.rtspUrl),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selector de duración
                DurationSelector(
                  onDurationSelected: (duration) {
                    setState(() {
                      _selectedDuration = duration;
                    });
                  },
                  initialDuration: _selectedDuration,
                ),
                // barra de progreso y cuenta regresiva
                if (_isRecording) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: 1 - (_recordingCountdown / _selectedDuration),
                          backgroundColor: Colors.grey[800],
                          color: Colors.green,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_recordingCountdown}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
                // fin barra de progreso y cuenta regresiva
                const SizedBox(height: 12),
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isRecording ? null : _startRecording,
                      icon: Icon(
                        _isRecording ? Icons.hourglass_top : Icons.fiber_manual_record,
                      ),
                      label: Text(
                        _isRecording
                            ? 'Grabando...'
                            : 'Grabar (${_selectedDuration}s)',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording ? Colors.orange : Colors.green,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: _openDownloadsFolder,
                      tooltip: 'Abrir carpeta de grabaciones',
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _takeSnapshot,
                      tooltip: 'Capturar fotograma',
                    ),
                    IconButton(
                      icon: const Icon(Icons.video_library),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecordingsListScreen(),
                          ),
                        );
                      },
                      tooltip: 'Mis grabaciones',
                    ),
                  ],
                ),
                if (_lastRecordedFile != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _playRecording,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lastRecordedFile!.split(Platform.pathSeparator).last,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}