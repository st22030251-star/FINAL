import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/firestore_service.dart';
import '../models/note_model.dart';
import '../services/ai_service.dart';

class CalendarScreen extends StatefulWidget {
  final String userId;
  const CalendarScreen({super.key, required this.userId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final FirestoreService _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const Divider(),
        Expanded(
          child: StreamBuilder<List<Note>>(
            stream: _firestore.getNotes(false, widget.userId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final allNotes = snapshot.data!;
              final dayNotes = allNotes.where((n) => isSameDay(n.date, _selectedDay)).toList();

              if (dayNotes.isEmpty) {
                return const Center(child: Text("No hay notas para este día"));
              }

              return ListView.builder(
                itemCount: dayNotes.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final n = dayNotes[index];
                  return Card(
                    child: ListTile(
                      title: Text(n.content),
                      subtitle: Text(n.isPrivate ? "Privada" : "Pública"),
                      trailing: IconButton(
                        icon: const Icon(Icons.auto_awesome, color: Colors.blueAccent),
                        onPressed: () => _summarize(n.content),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
