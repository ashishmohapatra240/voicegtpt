import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:text_to_speech/text_to_speech.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({super.key, required this.text, required this.sender});

  final String text;
  final String sender;

  @override
  Widget build(BuildContext context) {
    TextToSpeech tts = TextToSpeech();
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: AssetImage(sender == "user"
              ? "assets/images/user.png"
              : "assets/images/GTPT.png"),
        ),
        Expanded(
          child: text.trim().text.bodyText1(context).make().px8(),
        ),
      ],
    ).py8();
  }
}
