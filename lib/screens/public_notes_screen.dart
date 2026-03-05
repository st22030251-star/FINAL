import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import '../models/note_model.dart';

class PublicNotesScreen extends StatelessWidget {
  final String userId;
  const PublicNotesScreen({super.key, required this.userId});

  void _summarize(BuildContext context, String content) async {
    final ai = AIService();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    final summary = await ai.summarizeNote(content);
    if (context.mounted) {
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
    return StreamBuilder<List<Note>>(
      stream: FirestoreService().getNotes(false, userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final notes = snapshot.data!;
        if (notes.isEmpty) return const Center(child: Text("No hay notas públicas"));
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
                      onPressed: () => _summarize(context, n.content),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => FirestoreService().deleteNote(n.id),
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
