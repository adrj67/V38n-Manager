import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'camera_config.dart';

class AppConfig {
  static String getEnv(String key, {String defaultValue = ''}) {
    return dotenv.env[key] ?? defaultValue;
  }

  static List<CameraConfig> getCameras() {
    final cameras = <CameraConfig>[];
    int i = 1;
    while (true) {
      final name = getEnv('CAMERA_${i}_NAME');
      if (name.isEmpty) break; // Si no hay nombre, dejamos de buscar
      cameras.add(CameraConfig(
        id: i,
        name: name,
        ip: getEnv('CAMERA_${i}_IP'),
        rtspUrl: getEnv('CAMERA_${i}_RTSP_URL'),
        onvifUrl: getEnv('CAMERA_${i}_ONVIF_URL'),
        username: getEnv('CAMERA_${i}_USERNAME'),
        password: getEnv('CAMERA_${i}_PASSWORD'),
      ));
      i++;
    }
    return cameras;
  }
}