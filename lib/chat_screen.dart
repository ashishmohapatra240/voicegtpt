import 'dart:async';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:voicegtpt/chatmessage.dart';
import 'package:voicegtpt/threedots.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  ChatGPT? chatGPT;

  StreamSubscription? _subscription;
  bool _isTyping = false;

  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  TextToSpeech tts = TextToSpeech();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    chatGPT = ChatGPT.instance;
    _initSpeech();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
    setController();
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
    setController();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  void setController() {
    setState(() {
      _controller.text = _lastWords;
    });
  }

  void sendMessage() {
    ChatMessage message = ChatMessage(text: _controller.text, sender: "user");
    setState(() {
      _isTyping = true;
      _messages.insert(0, message);
      _controller.clear();
    });
    final request = CompleteReq(
        prompt: message.text, model: kTranslateModelV3, max_tokens: 200);

    _subscription = chatGPT!
        .builder("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",
            orgId: "")
        .onCompleteStream(request: request)
        .listen((event) {
      ChatMessage botMessage = ChatMessage(
        text: event!.choices[0].text,
        sender: "GTPT",
      );

      setState(() {
        _isTyping = false;
        _messages.insert(0, botMessage);
      });

      tts.speak(botMessage.text); 
    });
  }

  Widget _buildTextComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: (value) => sendMessage(),
            decoration: const InputDecoration.collapsed(
                hintText: "Question/description"),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () => sendMessage(),
        ),
      ],
    ).px16();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('VoiceGTPT'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
                child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            )),
            if (_isTyping) const ThreeDots(),
            const Divider(
              height: 1.0,
            ),
            Container(
              decoration: BoxDecoration(color: context.cardColor),
              child: _buildTextComposer(),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50.0),
        child: FloatingActionButton(
          onPressed:
              _speechToText.isNotListening ? _startListening : _stopListening,
          tooltip: 'Listen',
          child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
        ),
      ),
    );
  }
}
