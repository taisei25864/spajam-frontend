import 'package:flutter/material.dart';
import 'services/web_rtc.dart';

// final _webRTCService = WebRTCVoiceChatService();

Future<void> connectToSignalingServer() async {
  // Simulate a network call
  debugPrint('Connecting to signaling server...');
}

// !!! 実験用に編集しているのでmainはもとに戻す
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Debug Button Demo'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              connectToSignalingServer();
            },
            child: const Text('押してください'),
          ),
        ),
      ),
    );
  }
}