import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String chatApiUrl = "https://api.chatanywhere.tech/v1/chat/completions";
  static const String apiKey = "sk-ehl39TKLOfz7zfn7V6RtpUEV9XVWR5oJxkEk8LMAIA7UWPu1";
  static const String systemPrompt = """Eres el Asistente IA especializado de este Sistema POS (Punto de Venta).
Tu única función es ayudar al usuario con el funcionamiento de esta página, resolver errores técnicos del sistema y realizar cambios en la interfaz si se te solicita.

CONTEXTO DEL SISTEMA:
- Secciones:
  1. Terminal: Venta de productos, carrito, búsqueda y pago.
  2. Ventas: Historial de transacciones, estadísticas globales.
  3. Inventario: Listado de productos, SKU, categorías, precios y niveles de stock.

REGLAS CRÍTICAS:
1. SOLO habla de temas relacionados con este POS.
2. RECHAZA temas externos. Responde: "Lo siento, solo puedo ayudarte con dudas relacionadas con este sistema POS."
3. Habla siempre en español, sé directo, profesional y útil.""";

  final List<Map<String, String>> _chatHistory = [
    {"role": "system", "content": systemPrompt}
  ];

  List<Map<String, String>> get chatHistory => _chatHistory;

  Future<String> sendMessage(String message) async {
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
        final botResponse = data['choices'][0]['message']['content'];
        _chatHistory.add({"role": "assistant", "content": botResponse});
        return botResponse;
      } else {
        return "Error: \${response.statusCode}";
      }
    } catch (e) {
      return "Error de conexión: \$e";
    }
  }

  void clearChat() {
    _chatHistory.clear();
    _chatHistory.add({"role": "system", "content": systemPrompt});
  }
}
