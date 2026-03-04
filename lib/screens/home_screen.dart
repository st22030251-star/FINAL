import 'package:flutter/material.dart';
import 'terminal_screen.dart';
import 'inventory_screen.dart';
import 'ventas_screen.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _ai = AIService();
  final _auth = AuthService();
  final _messageController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];

  final List<Widget> _screens = [
    const TerminalScreen(),
    const InventoryScreen(),
    const VentasScreen(),
  ];

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({"role": "user", "content": text});
      _messageController.clear();
    });

    final response = await _ai.sendMessage(text);
    setState(() {
      _chatMessages.add({"role": "assistant", "content": response});
    });
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
                title: const Text("Asistente POS AI"),
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
                        decoration: const InputDecoration(hintText: "Pregunta algo sobre el sistema..."),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.send), onPressed: () async {
                      final text = _messageController.text.trim();
                      if (text.isEmpty) return;
                      
                      setModalState(() {
                        _chatMessages.add({"role": "user", "content": text});
                      });
                      _messageController.clear();
                      
                      final response = await _ai.sendMessage(text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SecurePOS AI"),
        actions: [
          IconButton(onPressed: () => _auth.signOut(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: "Terminal"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: "Stock"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Ventas"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showChat,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}
