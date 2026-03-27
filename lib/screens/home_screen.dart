import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gal/gal.dart';
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

  late AudioRecorder _audioRecorder;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _getDeviceId();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
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

  Future<void> _takePhoto() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      
      if (photo != null) {
        // Guardar la foto en el almacenamiento de la aplicación
        final directory = await getApplicationDocumentsDirectory();
        final String path = directory.path;
        final String fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File localImage = File('$path/$fileName');
        
        await File(photo.path).copy(localImage.path);
        
        // Guardar también en la galería (Almacenamiento)
        await Gal.putImage(localImage.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Foto guardada en app y galería: ${localImage.path}")),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permiso de cámara denegado")),
        );
      }
    }
  }

  Future<void> _recordAudio() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Audio grabado en: $path")),
        );
        // Aquí se podría guardar la nota con el path del audio
        FirestoreService().addNote("Recordatorio de voz guardado", _currentIndex == 1, _deviceId);
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final String path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permiso de micrófono denegado")),
          );
        }
      }
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Los servicios de ubicación están desactivados")),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permiso de ubicación denegado")),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permisos de ubicación permanentemente denegados")),
        );
      }
      return;
    }

    final Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      final noteContent = "Ubicación actual: Lat: ${position.latitude}, Lon: ${position.longitude}";
      FirestoreService().addNote(noteContent, _currentIndex == 1, _deviceId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ubicación guardada: ${position.latitude}, ${position.longitude}")),
      );
    }
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
            onPressed: _getLocation,
            heroTag: "location",
            backgroundColor: Colors.purple,
            child: const Icon(Icons.location_on, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _recordAudio,
            heroTag: "record",
            backgroundColor: _isRecording ? Colors.red : Colors.pink,
            child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _takePhoto,
            heroTag: "take_photo",
            backgroundColor: Colors.orange,
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
          const SizedBox(height: 16),
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
