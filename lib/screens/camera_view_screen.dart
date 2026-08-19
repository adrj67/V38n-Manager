import 'package:flutter/material.dart';
import '../core/config/camera_config.dart';
import '../widgets/rtsp_player_widget.dart';

class CameraViewScreen extends StatelessWidget {
  final CameraConfig camera;

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
          // El reproductor RTSP ocupa la mayor parte de la pantalla
          Expanded(
            flex: 4,
            child: RtspPlayerWidget(rtspUrl: camera.rtspUrl),
          ),
          // Barra de herramientas inferior (placeholder para futuras funciones)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.folder_open, color: Colors.white),
                  onPressed: () {
                    // Aquí iremos a la lista de grabaciones (Día 9-10)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Funcionalidad próxima: Grabaciones')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () {
                    // Aquí iremos a descargas (Día 13-14)
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