import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart'; // 🔥 IMPORT TTS

class SakhaChatScreen extends StatefulWidget {
  const SakhaChatScreen({Key? key}) : super(key: key);

  @override
  State<SakhaChatScreen> createState() => _SakhaChatScreenState();
}

class _SakhaChatScreenState extends State<SakhaChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  // Voice & TTS variables
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isLoading = false;
  bool _usedVoiceForCurrentMessage = false; // 🔥 Tracks if the current input came from voice

  // Gemini variables
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
    _initializeSakha();
  }

  @override
  void dispose() {
    _flutterTts.stop(); // Stop speaking if the user leaves the screen
    super.dispose();
  }

  // 🔥 Initialize Text-To-Speech settings
  void _initTts() async {
    await _flutterTts.setLanguage("hi-IN"); // Good default for Hinglish/Hindi
    await _flutterTts.setSpeechRate(0.5); // Slightly slower for clear understanding
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _initializeSakha() {
    final promptInstruction = Content.system(
        "You are 'Sakha', a friendly, respectful, and highly knowledgeable agricultural expert assistant for farmers in India. "
            "CRITICAL LANGUAGE RULES: "
            "1. You MUST detect the exact language and script the user is typing in, and reply ONLY in that exact language and script. "
            "2. If the user types in pure English (e.g., 'who are you'), reply ONLY in pure English. "
            "3. If the user types in Hinglish (e.g., 'kaise ho'), reply in Hinglish. "
            "4. If the user types in Hindi script (e.g., 'आप कैसे हैं'), reply in Hindi script. "
            "5. Keep answers practical, simple, and short so they are easy to listen to."
    );

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
      systemInstruction: promptInstruction,
    );

    _chatSession = _model.startChat();

    _messages.add({"role": "sakha", "text": "Namaste! I am Sakha, your farming companion. How can I help you today?"});
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() => _isListening = true);
        // 🔥 Stop any ongoing speech if the user starts talking
        _flutterTts.stop();

        _speech.listen(
          onResult: (val) {
            setState(() {
              _controller.text = val.recognizedWords;
              _usedVoiceForCurrentMessage = true; // 🔥 Mark that this text came from the mic!
            });

            // Optional: Auto-send if the voice engine confirms the user stopped talking
            // if (val.finalResult) {
            //   _sendMessage();
            // }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          localeId: 'en-IN',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }

    // Capture the state before resetting
    bool respondWithVoice = _usedVoiceForCurrentMessage;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
      _usedVoiceForCurrentMessage = false; // Reset for the next message
    });

    _controller.clear();

    try {
      final response = await _chatSession.sendMessage(Content.text(text));
      final botText = response.text ?? "Sorry, I could not understand that.";

      setState(() {
        _messages.add({"role": "sakha", "text": botText});
      });

      // 🔥 If the user used their voice to ask, Sakha talks back!
      if (respondWithVoice) {
        await _flutterTts.speak(botText);
      }

    } catch (e) {
      print('🚨 GEMINI API ERROR: $e');
      setState(() {
        _messages.add({"role": "sakha", "text": "Error connecting to the server. Please check your internet."});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Sakha'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primaryGreen : AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                        bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                      border: Border.all(color: AppColors.primaryGreen, width: 1),
                    ),
                    child: Text(
                      message["text"]!,
                      style: TextStyle(color: isUser ? AppColors.textDark : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: AppColors.darkGreen),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _listen,
            child: CircleAvatar(
              backgroundColor: _isListening ? Colors.redAccent : AppColors.cardWhite,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.white : AppColors.darkGreen,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              // 🔥 If the user types manually, ensure we turn OFF voice mode
              onChanged: (text) {
                if (_usedVoiceForCurrentMessage) {
                  _usedVoiceForCurrentMessage = false;
                }
              },
              decoration: InputDecoration(
                hintText: _isListening ? 'Listening...' : 'Type your question...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppColors.backgroundGreen,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.darkGreen,
            child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
          )
        ],
      ),
    );
  }
}