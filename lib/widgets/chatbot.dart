import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatBotWidget extends StatefulWidget {
  const ChatBotWidget({super.key});

  @override
  _ChatBotWidgetState createState() => _ChatBotWidgetState();
}

class _ChatBotWidgetState extends State<ChatBotWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add({
        "data": 0,
        "message": "Benvenuto, sono qui per aiutarti ad apprendere a risparmiare, investire o semplicemente gestire meglio il tuo denaro! "
            "\n\nRicorda: le decisioni finanziarie richiedono tempo e riflessione. "
            "\"Un soldo risparmiato è un soldo guadagnato\", diceva il buon vecchio Poor Richard. "
            "\n\nSe hai dubbi, ti invito a rivolgerti ad un consulente finanziario accreditato, "
            "ma nel frattempo, sono a tua disposizione per fare chiarezza e guidarti verso un futuro finanziario più sereno!"
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add({"data": 1, "message": _controller.text});
    });
    FocusScope.of(context).unfocus();

    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/chatbot/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"message": _controller.text}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        _messages.add({"data": 0, "message": responseData['response']});
      });
    } else {
      setState(() {
        _messages.add(
            {"data": 0, "message": "Errore nella risposta dal server."});
      });
    }

    _controller.clear();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.grey[200],
          child: Column(
            children: <Widget>[
              const SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageItem(_messages[index]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Scrivi un messaggio...",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: _sendMessage,
                      backgroundColor: Colors.black,
                      mini: true,
                      child: const Icon(Icons.send,
                          color: Colors.white,
                          size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    return Align(
      alignment: message['data'] == 1 ? Alignment.centerRight : Alignment
          .centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 40.0, right: 40.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: message['data'] == 1 ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: message['data'] == 1
                        ? const Radius.circular(16)
                        : const Radius.circular(0),
                    bottomRight: message['data'] == 1
                        ? const Radius.circular(0)
                        : const Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message['message'],
                  style: TextStyle(
                    color: message['data'] == 1 ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: message['data'] == 0 ? 0 : null,
              right: message['data'] == 1 ? 0 : null,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: message['data'] == 1 ? Colors.black : Colors
                    .grey,
                child: Icon(
                  message['data'] == 1 ? Icons.mood : Icons.support_agent,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
