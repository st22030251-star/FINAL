import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'public_notes_screen.dart';
import 'notes_screen.dart';
import 'calendar_screen.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _ai = AIService();
  final _messageController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  String _deviceId = 'unknown';
  bool _isLoadingId = true;

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }

  Future<void> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String id = 'unknown';
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        id = androidInfo.id; // Unique ID on Android
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        id = iosInfo.identifierForVendor ?? 'unknown_ios';
      }
    } catch (e) {
      debugPrint("Error getting device ID: $e");
    }
    if (mounted) {
      setState(() {
        _deviceId = id;
        _isLoadingId = false;
      });
    }
  }

  void _showChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              AppBar(
                title: const Text("Asistente IA de Notas"),
                actions: [
                  IconButton(onPressed: () {
                    _ai.clearChat();
                    setModalState(() => _chatMessages.clear());
                  }, icon: const Icon(Icons.refresh))
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _chatMessages.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final m = _chatMessages[index];
                    final isUser = m['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          m['content'] ?? '',
                          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(hintText: "Escribe algo..."),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.send), onPressed: () async {
                      final text = _messageController.text.trim();
                      if (text.isEmpty) return;
                      
                      setModalState(() {
                        _chatMessages.add({"role": "user", "content": text});
                      });
                      _messageController.clear();
                      
                      final response = await _ai.sendMessage(text, _deviceId);
                      setModalState(() {
                        _chatMessages.add({"role": "assistant", "content": response});
                      });
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addNoteManual() async {
    final controller = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isPrivate = _currentIndex == 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isPrivate ? "Nueva Nota Privada" : "Nueva Nota Pública"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(hintText: "Contenido de la nota"),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text("Fecha: ${selectedDate.toString().substring(0, 10)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  FirestoreService().addNote(controller.text, isPrivate, _deviceId, date: selectedDate);
                  Navigator.pop(context);
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingId) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String title = "Mis Notas";
    if (_currentIndex == 1) title = "Notas Privadas";
    if (_currentIndex == 2) title = "Calendario";

    final screens = [
      PublicNotesScreen(userId: _deviceId),
      NotesScreen(userId: _deviceId),
      CalendarScreen(userId: _deviceId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.note), label: "Públicas"),
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: "Privadas"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Calendario"),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _addNoteManual,
            heroTag: "add_manual",
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _showChat,
            heroTag: "chat_ai",
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
