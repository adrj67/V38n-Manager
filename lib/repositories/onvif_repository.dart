// TODO: Implementar ONVIF correctamente después de investigar la API.
// Por ahora, esto es un placeholder para no bloquear la compilación.

class OnvifRepository {
  final String onvifUrl;
  final String username;
  final String password;

  OnvifRepository({
    required this.onvifUrl,
    required this.username,
    required this.password,
  });

  // Placeholder: no hace nada real
  Future<void> connect() async {
    // Simular conexión
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<List<dynamic>> getRecordings() async {
    // Retornar lista vacía
    return [];
  }

  Future<String> getRecordingUrl(String recordingToken) async {
    return '';
  }
}