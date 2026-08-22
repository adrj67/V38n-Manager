import 'package:flutter/material.dart';
import '../core/config/camera_config.dart';
import '../widgets/rtsp_player_widget.dart';
import 'recordings_screen.dart'; // importar la nueva pantalla
import '../repositories/onvif_repository.dart';

class CameraViewScreen extends StatelessWidget {
  final CameraConfig camera; // debe ser exactamente 'camera'

  const CameraViewScreen({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(camera.name),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: RtspPlayerWidget(rtspUrl: camera.rtspUrl),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.folder_open, color: Colors.white),
                  onPressed: () {
                    // Navegar a la pantalla de grabaciones (placeholder)
                    final repo = OnvifRepository(
                      onvifUrl: camera.onvifUrl,
                      username: camera.username,
                      password: camera.password,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordingsScreen(repository: repo),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Funcionalidad próxima: Descargas')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}