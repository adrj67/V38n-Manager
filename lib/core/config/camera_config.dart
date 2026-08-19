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