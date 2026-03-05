import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firestore_service.dart';

class AIService {
  static const String chatApiUrl = "https://api.chatanywhere.tech/v1/chat/completions";
  static const String apiKey = "sk-ehl39TKLOfz7zfn7V6RtpUEV9XVWR5oJxkEk8LMAIA7UWPu1";
  static const String systemPrompt = """Eres un Asistente IA especializado en gestión de notas personales.
Tu función es ayudar al usuario a organizar sus ideas, resumir textos largos y responder preguntas sobre el contenido de sus notas.

CAPACIDAD ESPECIAL:
Si el usuario te pide crear, guardar o anotar algo (ej. "Anota que debo comprar pan" o "Crea una nota sobre la reunión"), debes realizar dos acciones:
1. Responder confirmando que has guardado la nota.
2. Incluir la palabra clave [SAVE_NOTE: contenido de la nota] al final de tu respuesta.
Ejemplo de respuesta: "Claro, he anotado que debes comprar pan. [SAVE_NOTE: Comprar pan]" """;

  final List<Map<String, String>> _chatHistory = [
    {"role": "system", "content": systemPrompt}
  ];

  List<Map<String, String>> get chatHistory => _chatHistory;

  Future<String> sendMessage(String message, String userId) async {
    _chatHistory.add({"role": "user", "content": message});

    try {
      final response = await http.post(
        Uri.parse(chatApiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey"
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": _chatHistory,
          "max_tokens": 150,
          "temperature": 0.7
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String botResponse = data['choices'][0]['message']['content'];
        
        if (botResponse.contains("[SAVE_NOTE:")) {
          final regExp = RegExp(r"\[SAVE_NOTE:\s*(.*?)\]");
          final match = regExp.firstMatch(botResponse);
          if (match != null) {
            final noteContent = match.group(1);
            if (noteContent != null && noteContent.isNotEmpty) {
              await FirestoreService().addNote(noteContent, false, userId, date: DateTime.now());
            }
          }
        }

        _chatMessagesCleaner(botResponse);
        return botResponse;
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error de conexión: $e";
    }
  }

  void _chatMessagesCleaner(String response) {
     _chatHistory.add({"role": "assistant", "content": response});
  }

  Future<String> summarizeNote(String noteContent) async {
    try {
      final response = await http.post(
        Uri.parse(chatApiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey"
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "system", "content": "Eres un asistente que resume notas personales. Sé breve y directo."},
            {"role": "user", "content": "Resume esta nota: $noteContent"}
          ],
          "max_tokens": 100,
          "temperature": 0.5
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error de conexión: $e";
    }
  }

  void clearChat() {
    _chatHistory.clear();
    _chatHistory.add({"role": "system", "content": systemPrompt});
  }
}
