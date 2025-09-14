import 'dart:io';
import 'dart:convert';

void main() async {
  try {
    // WebSocketに接続
    final socket = await WebSocket.connect('ws://localhost:8000/ws_test');
    print('Connected to WebSocket server');

    // ハンドシェイクが成功したら自動的に確立される
    
    // JSONデータを作成
    final data = {
      'type': 'offer',
      'content': 'Hello Server!',
      'timestamp': DateTime.now().toIso8601String(),
    };

    // JSONデータを送信
    socket.add(jsonEncode(data));
    print('Sent JSON data: $data');

    // サーバーからのメッセージを受信
    socket.listen(
      (message) {
        print('Received message: $message');
      },
      onError: (error) {
        print('Error: $error');
      },
      onDone: () {
        print('Connection closed');
      },
    );

    // 5秒後に接続を閉じる
    await Future.delayed(Duration(seconds: 5));
    await socket.close();
  } catch (e) {
    print('Error occurred: $e');
  }
}