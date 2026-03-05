import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/biometric_service.dart';
import '../services/ai_service.dart';
import '../models/note_model.dart';

class NotesScreen extends StatefulWidget {
  final String userId;
  const NotesScreen({super.key, required this.userId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _firestore = FirestoreService();
  final _bio = BiometricService();
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    final ok = await _bio.authenticate();
    if (mounted) setState(() => _unlocked = ok);
  }

  void _summarize(String content) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    final summary = await AIService().summarizeNote(content);
    if (mounted) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Resumen IA"),
          content: Text(summary),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar"))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Sección Bloqueada"),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _authenticate, child: const Text("Desbloquear con Huella")),
          ],
        ),
      );
    }

    return StreamBuilder<List<Note>>(
      stream: _firestore.getNotes(true, widget.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final notes = snapshot.data!;
        if (notes.isEmpty) return const Center(child: Text("No hay notas privadas"));
        return ListView.builder(
          itemCount: notes.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final n = notes[index];
            return Card(
              child: ListTile(
                title: Text(n.content),
                subtitle: Text("Para: ${n.date.toString().substring(0, 10)}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, color: Colors.blueAccent),
                      onPressed: () => _summarize(n.content),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _firestore.deleteNote(n.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
