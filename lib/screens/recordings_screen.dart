import 'package:flutter/material.dart';
import '../repositories/onvif_repository.dart';

class RecordingsScreen extends StatefulWidget {
  final OnvifRepository repository;

  const RecordingsScreen({Key? key, required this.repository}) : super(key: key);

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  List<dynamic> _recordings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.repository.connect();
      final recordings = await widget.repository.getRecordings();
      setState(() {
        _recordings = recordings;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar grabaciones: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grabaciones (placeholder)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRecordings,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _recordings.isEmpty
                  ? const Center(child: Text('No hay grabaciones (placeholder)'))
                  : ListView.builder(
                      itemCount: _recordings.length,
                      itemBuilder: (context, index) {
                        final recording = _recordings[index];
                        return ListTile(
                          leading: const Icon(Icons.video_file),
                          title: Text(recording.toString()),
                          trailing: const Icon(Icons.download),
                          onTap: () {},
                        );
                      },
                    ),
    );
  }
}