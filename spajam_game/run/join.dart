import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart join.dart <user_id> <room_id>');
    return;
  }

  final user_id = args[0]; // 自分のid
  final room_id = args.length > 1 ? args[1] : 'testid';

  var sdpOffer = "";

  // 保持している通信相手のリスト
  List<String> connectedUsers = [];
  List<String> sdpSharedUsers = [];

  final socket = await WebSocket.connect('ws://localhost:8000/ws_test');
  try {
    print('Connected to WebSocket server');

    // メッセージ受信のリスナーを設定
    socket.listen(
      (message) {
        try {
          // 受信したメッセージをJSONとしてパース
          final decodedMessage = jsonDecode(message);
          print('Received message: ${jsonEncode(decodedMessage)}');

          if (decodedMessage["type"] == "joined") {
            var user = decodedMessage["user"];
            print('user :  $user');

            if (user != user_id && !sdpSharedUsers.contains(user)) {
              message = {
                'type': 'sdp_offer',
                'sdp': sdpOffer,
                'to': user,
                'from': user_id,
              };
              socket.add(jsonEncode(message));
            }
          } else if (decodedMessage["type"] == "joined_first") {
            sdpOffer = "DUMMY_SDP_OFFER";
          } else if (decodedMessage["type"] == "sdp_offer") {
            print('Received SDP offer from ${decodedMessage["from"]}');
          }
        } catch (e) {
          // JSONパースに失敗した場合は生のメッセージを表示
          print('Received raw message: $message');
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );

    // joinメッセージを送信
    final joinData = {'type': 'join', 'user_id': user_id, 'room_id': room_id};
    socket.add(jsonEncode(joinData));
    print('Sent join request: ${jsonEncode(joinData)}');

    // コネクションを維持
    await Future.delayed(Duration(days: 1));
  } catch (e) {
    print('Connection error: $e');
  } finally {
    await socket?.close();
    print('WebSocket connection closed');
  }
}
