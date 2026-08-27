import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/config/camera_config.dart';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cameras = AppConfig.getCameras();

    return Scaffold(
      appBar: AppBar(title: const Text('V38n Manager')),
      body: cameras.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, size: 48, color: Colors.orange),
                  SizedBox(height: 16),
                  Text('No hay cámaras configuradas'),
                  Text('Revisa tu archivo assets/.env'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: cameras.length,
              itemBuilder: (context, index) {
                final cam = cameras[index];
                return ListTile(
                  leading: const Icon(Icons.videocam),
                  title: Text(cam.name),
                  subtitle: Text(cam.ip),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CameraScreen(camera: cam),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}