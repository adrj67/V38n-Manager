import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class RtspPlayerWidget extends StatefulWidget {
  final String rtspUrl;
  final bool autoPlay;

  const RtspPlayerWidget({
    Key? key,
    required this.rtspUrl,
    this.autoPlay = true,
  }) : super(key: key);

  @override
  State<RtspPlayerWidget> createState() => _RtspPlayerWidgetState();
}

class _RtspPlayerWidgetState extends State<RtspPlayerWidget> {
  late Player _player;
  late VideoController _controller;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isMuted = false;
  String? _errorMessage;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    // Suscribirse a cambios de estado
    _player.stream.position.listen((_) {
      if (!_isPlaying && !_isLoading) {
        setState(() => _isPlaying = true);
      }
    });
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _player.open(
        Media(widget.rtspUrl),
        play: widget.autoPlay,
      );
      setState(() {
        _isLoading = false;
        _isPlaying = widget.autoPlay;
        _retryCount = 0;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al conectar: $e';
      });
      debugPrint('❌ Error RTSP: $e');
      // Intentar reconexión automática
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _errorMessage != null) {
          debugPrint('🔄 Reintentando conexión (intento $_retryCount/$_maxRetries)');
          _initializePlayer();
        }
      });
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _player.setVolume(_isMuted ? 0 : 100);
    });
  }

  void _retryManually() {
    _retryCount = 0;
    _initializePlayer();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si hay error
    if (_errorMessage != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _retryManually,
                icon: const Icon(Icons.refresh),
                label: Text(_retryCount > 0 
                  ? 'Reintentar (${_retryCount}/$_maxRetries)'
                  : 'Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Si está cargando
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Conectando con la cámara...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    // Todo bien: mostrar video con overlay de controles
    return Stack(
      fit: StackFit.expand,
      children: [
        Video(
          controller: _controller,
          fit: BoxFit.contain,
        ),
        // Overlay con controles (solo aparece al tocar la pantalla)
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              // Aquí podríamos mostrar/ocultar controles, pero por simplicidad
              // los dejamos visibles siempre.
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Controles en la parte inferior
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: _togglePlayPause,
                ),
                IconButton(
                  icon: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _toggleMute,
                ),
                // Indicador de estado
                Text(
                  _isPlaying ? '🔴 En vivo' : '⏸ Pausado',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}