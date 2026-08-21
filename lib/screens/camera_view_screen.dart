import 'package:flutter/material.dart';
import '../core/config/camera_config.dart';
import '../widgets/rtsp_player_widget.dart';

class CameraViewScreen extends StatefulWidget {
  final CameraConfig camera;

  const CameraViewScreen({Key? key, required this.camera}) : super(key: key);

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  bool _isFullscreen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullscreen
          ? null // Ocultar app bar en fullscreen
          : AppBar(
              title: Text(widget.camera.name),
              backgroundColor: Colors.black,
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () {
                    setState(() => _isFullscreen = !_isFullscreen);
                  },
                ),
              ],
            ),
      body: Column(
        children: [
          // El reproductor RTSP ocupa la mayor parte
          Expanded(
            flex: 4,
            child: RtspPlayerWidget(rtspUrl: widget.camera.rtspUrl),
          ),
          // Barra de herramientas inferior (funcionalidades futuras)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolButton(
                  icon: Icons.folder_open,
                  label: 'Grabaciones',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente: Grabaciones')),
                    );
                  },
                ),
                _buildToolButton(
                  icon: Icons.download,
                  label: 'Descargar',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente: Descargas')),
                    );
                  },
                ),
                _buildToolButton(
                  icon: Icons.info_outline,
                  label: 'Info',
                  onTap: () {
                    _showCameraInfo();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  void _showCameraInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.camera.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IP: ${widget.camera.ip}'),
            const SizedBox(height: 8),
            Text('RTSP: ${widget.camera.rtspUrl}'),
            const SizedBox(height: 8),
            Text('ONVIF: ${widget.camera.onvifUrl}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}