import 'dart:io';
import 'dart:async';

Future<void> connectWebSocket() async {
  const host = '172.18.217.184'; // サーバのIPアドレスにあわせて変更してください
  const port = 8000;
  const serverUrl = 'ws://$host:$port'; // サーバのURLに変更してください
  try {
    final socket = await WebSocket.connect(serverUrl+"/ws/2d4f73/userA");
    print('Connected to $serverUrl');

    // サーバからのメッセージを受信
    socket.listen(
      (data) {
        print('Received: $data');
      },
      onDone: () {
        print('Connection closed');
      },
      onError: (error) {
        print('Error: $error');
      },
    );

    // // 送信するデータ
    // socket.add('Hello server!');
    // print('Sent: Hello server!');

    // 接続を保持したい場合は適宜待機
    await Future.delayed(Duration(seconds: 10));
    await socket.close();
    print('Socket closed');
  } catch (e) {
    print('Could not connect: $e');
  }
}

void main() async {
  await connectWebSocket();
}
