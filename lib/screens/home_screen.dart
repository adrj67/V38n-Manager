import 'package:flutter/material.dart';
import '../core/config/app_config.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cameras = AppConfig.getCameras();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('V38n Manager'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: cameras.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber, size: 60, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'No hay cámaras configuradas',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Crea un archivo assets/.env con tus cámaras',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: cameras.length,
              itemBuilder: (context, index) {
                final camera = cameras[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.videocam, color: Colors.blue),
                    title: Text(camera.name),
                    subtitle: Text('IP: ${camera.ip}'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Por ahora solo mostraremos un diálogo
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(camera.name),
                          content: Text('RTSP: ${camera.rtspUrl}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}