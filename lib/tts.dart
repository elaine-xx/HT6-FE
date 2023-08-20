import 'package:flutter_tts/flutter_tts.dart';

class TtsManager {
  late FlutterTts flutterTts;

  TtsManager() {
    initTts();
  }

  initTts() {
    flutterTts = FlutterTts();
    // Set up event handlers and options similar to your main.dart
    // ...
  }

  Future<void> speak(String text) async {
    await flutterTts.setVolume(0.5);
    await flutterTts.setSpeechRate(0.6);
    await flutterTts.setPitch(1.0);

    await flutterTts.speak(text);
  }

  Future<void> stop() async {
    await flutterTts.stop();
  }

  void dispose() {
    flutterTts.stop();
  }
}
