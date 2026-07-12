import 'package:flutter/material.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class GovernmentSchemesScreen extends StatefulWidget {
  const GovernmentSchemesScreen({Key? key}) : super(key: key);

  @override
  State<GovernmentSchemesScreen> createState() => _GovernmentSchemesScreenState();
}

class _GovernmentSchemesScreenState extends State<GovernmentSchemesScreen> {
  // 🔥 Removed 'final' so we can add to this list dynamically
  List<Map<String, String>> schemes = [
    {
      "title": "PM-KISAN Samman Nidhi",
      "short": "₹6,000/year direct support.",
      "details": "Under this scheme, an income support of 6,000/- per year in three equal installments is provided to all landholding farmer families. You need your Aadhaar card, bank account details, and land holding papers to apply.",
    },
    {
      "title": "Pradhan Mantri Fasal Bima Yojana",
      "short": "Crop Insurance Scheme.",
      "details": "Provides insurance coverage and financial support to farmers in the event of failure of any of the notified crops as a result of natural calamities, pests & diseases. Premium is very low (1.5% to 2%).",
    },
    {
      "title": "Agriculture Equipment Subsidy",
      "short": "Up to 50% off on tractors & tools.",
      "details": "The government provides massive subsidies on purchasing new tractors, rotavators, and irrigation pipes to modernize farming. Apply via your state's DBT agriculture portal.",
    }
  ];

  // 🔥 Dialog to Add a New Scheme
  void _showAddSchemeDialog() {
    final titleController = TextEditingController();
    final shortController = TextEditingController();
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Scheme", style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Scheme Title", hintText: "e.g. Solar Pump Yojana", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: shortController,
                decoration: const InputDecoration(labelText: "Short Summary", hintText: "e.g. 60% subsidy on pumps", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Full Details", hintText: "Explain who is eligible and how to apply...", border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () {
              if (titleController.text.isEmpty || detailsController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in the title and details!"), backgroundColor: Colors.red));
                return;
              }

              // Update the state with the new scheme
              setState(() {
                schemes.insert(0, { // Inserts at the top of the list!
                  "title": titleController.text,
                  "short": shortController.text.isNotEmpty ? shortController.text : "User added scheme",
                  "details": detailsController.text,
                });
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Scheme added successfully!"), backgroundColor: AppColors.darkGreen));
            },
            child: const Text("Add Scheme", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Govt. Schemes Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          // 🔥 The new Add Button in the AppBar
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            tooltip: "Add a new scheme",
            onPressed: _showAddSchemeDialog,
          )
        ],
      ),

      // 1. THE EXPANDABLE LIST
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: schemes.length,
        itemBuilder: (context, index) {
          final scheme = schemes[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ExpansionTile(
              title: Text(scheme["title"]!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen, fontSize: 18)),
              subtitle: Text(scheme["short"]!, style: const TextStyle(color: Colors.grey)),
              childrenPadding: const EdgeInsets.all(20),
              children: [
                Text(scheme["details"]!, style: const TextStyle(fontSize: 15, height: 1.5)),
              ],
            ),
          );
        },
      ),

      // 2. THE FLOATING CORNER CHATBOT
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openChatBot(context),
        backgroundColor: AppColors.darkGreen,
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text("Ask KisanBot", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _openChatBot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ChatBotUI(),
    );
  }
}

// --- THE CHAT INTERFACE ---
class _ChatBotUI extends StatefulWidget {
  const _ChatBotUI({Key? key}) : super(key: key);

  @override
  State<_ChatBotUI> createState() => _ChatBotUIState();
}

class _ChatBotUIState extends State<_ChatBotUI> {
  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  late FlutterTts _flutterTts;

  bool _isLoading = false;
  bool _isListening = false;
  bool _usedVoiceForCurrentMessage = false;

  final List<Map<String, dynamic>> _messages = [];

  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _initTts();

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: 'AIzaSyBXObRkeqMUkddhFIyxmQu9SpvwVg9KInE', // Note: Secure this later!
      systemInstruction: Content.system(
          "You are KisanBot, an expert AI for Indian farmers. "
              "1. Answer questions ONLY about agriculture, farming schemes, subsidies, and crops. "
              "2. CRITICAL: Always reply in the EXACT SAME LANGUAGE the user used to ask the question. "
              "3. Keep answers short, bulleted, and easy to read on mobile."
      ),
    );

    _chat = _model.startChat();

    _messages.add({
      "isUser": false,
      "text": "Namaste! I am KisanBot. You can ask me about schemes, subsidies, or farming in English, Hindi, or your local language."
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }

    bool respondWithVoice = _usedVoiceForCurrentMessage;

    setState(() {
      _messages.add({"isUser": true, "text": text});
      _isLoading = true;
      _usedVoiceForCurrentMessage = false;
      _controller.clear();
    });

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final botText = response.text ?? "I couldn't generate an answer.";

      setState(() {
        _messages.add({
          "isUser": false,
          "text": botText
        });
      });

      if (respondWithVoice) {
        await _flutterTts.speak(botText);
      }

    } catch (e) {
      setState(() {
        _messages.add({
          "isUser": false,
          "text": "Connection Failed. Please check your internet or API Key."
        });
      });
      print("Gemini Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() => _isListening = true);
        _flutterTts.stop();

        _speech.listen(
          onResult: (val) => setState(() {
            _controller.text = val.recognizedWords;
            _usedVoiceForCurrentMessage = true;
          }),
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          localeId: 'en-IN',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Microphone permission denied."))
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_controller.text.isNotEmpty) {
        _sendMessage(_controller.text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 15, right: 15, top: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("KisanBot AI Assistant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
            ],
          ),
          const Divider(),

          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["isUser"];
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.darkGreen : AppColors.primaryGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: Radius.circular(isUser ? 15 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 15),
                      ),
                    ),
                    child: Text(
                        msg["text"],
                        style: TextStyle(fontSize: 15, color: isUser ? Colors.white : Colors.black87)
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text("KisanBot is typing...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ),

          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (text) {
                      if (_usedVoiceForCurrentMessage) {
                        _usedVoiceForCurrentMessage = false;
                      }
                    },
                    decoration: InputDecoration(
                      hintText: _isListening ? "Listening..." : "Type or tap mic...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),

                GestureDetector(
                  onTap: _listen,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: _isListening ? Colors.redAccent : Colors.grey.shade300,
                    child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(width: 8),

                GestureDetector(
                  onTap: () => _sendMessage(_controller.text),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.darkGreen,
                    child: _isLoading
                        ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}