import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String getEnv(String key, {String defaultValue = ''}) {
    return dotenv.env[key] ?? defaultValue;
  }

  static List<CameraConfig> getCameras() {
    final cameras = <CameraConfig>[];
    int i = 1;
    while (true) {
      final name = getEnv('CAMERA_${i}_NAME');
      if (name.isEmpty) break;
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

class CameraConfig {
  final int id;
  final String name;
  final String ip;
  final String rtspUrl;
  final String onvifUrl;
  final String username;
  final String password;

  const CameraConfig({
    required this.id,
    required this.name,
    required this.ip,
    required this.rtspUrl,
    required this.onvifUrl,
    required this.username,
    required this.password,
  });
}