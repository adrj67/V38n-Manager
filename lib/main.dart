import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:media_kit/media_kit.dart';  // <-- Importar media_kit
import 'core/config/app_config.dart';
import 'screens/camera_view_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar media_kit ANTES de cualquier otra cosa
  MediaKit.ensureInitialized();

  // 2. Cargar variables de entorno
  try {
    await dotenv.load(fileName: 'assets/.env');
    print('✅ .env cargado correctamente');
  } catch (e) {
    print('❌ Error al cargar .env: $e');
  }

  // 3. Ejecutar la app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'V38n Manager',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

// Ahora es HomeScreen (antes ConfigTestScreen)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cameras = AppConfig.getCameras();
    return Scaffold(
      appBar: AppBar(
        title: const Text('V38n Manager'),
      ),
      body: cameras.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'No hay cámaras configuradas.\nRevisa tu archivo assets/.env',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: cameras.length,
              itemBuilder: (context, index) {
                final cam = cameras[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: Text(cam.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('IP: ${cam.ip}'),
                        Text('RTSP: ${cam.rtspUrl}'),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navegamos a la pantalla de la cámara
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CameraViewScreen(camera: cam),
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