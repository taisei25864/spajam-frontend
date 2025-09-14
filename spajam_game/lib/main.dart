import 'package:flutter/material.dart';
import 'services/web_rtc.dart';

// final _webRTCService = WebRTCVoiceChatService();

Future<void> connectToSignalingServer() async {
  final signalingService = SignalingService(
    myId: 'user${DateTime.now().second}',
    roomId: 'testid',
    serverUrl: 'ws://localhost:8000/ws_test',
  );

  try {
    await signalingService.connect();
    debugPrint('Connected to signaling server');
  } catch (e) {
    debugPrint('Failed to connect to signaling server: $e');
  }
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
        appBar: AppBar(title: const Text('Debug Button Demo')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              await connectToSignalingServer();
            },
            child: const Text('押してください'),
          ),
        ),
      ),
    );
  }
}
