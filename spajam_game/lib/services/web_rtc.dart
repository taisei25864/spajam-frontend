import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'flutter_webrtc/flutter_webrtc.dart';

class SignalingService {
  WebSocket? _socket;
  final String _myId;
  final String _roomId;
  final String _serverUrl;
  String _sdpOffer = "";

  // コールバック関数の定義
  Function(String)? onUserJoined;
  Function(String, String)? onSdpOfferReceived;

  SignalingService({
    required String myId,
    required String roomId,
    required String serverUrl,
  }) : _myId = myId,
       _roomId = roomId,
       _serverUrl = serverUrl; // -> ws://localhost:8000/ws_test

  Future<void> connect() async {
    try {
      _socket = await WebSocket.connect(_serverUrl);
      print('[LOG]Connected to WebSocket server');
      _setupMessageListener();
      await _joinRoom();
    } catch (e) {
      print('[LOG]Connection error: $e');
      rethrow;
    }
  }

  void _setupMessageListener() {
    _socket?.listen(
      (message) {
        try {
          final decodedMessage = jsonDecode(message);
          _handleMessage(decodedMessage);
        } catch (e) {
          print('[LOG]Error handling message: $e');
        }
      },
      onError: (error) => print('[LOG]WebSocket error: $error'),
      onDone: () => print('[LOG]WebSocket connection closed'),
    );
  }

  void _handleMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'joined':
        final user = message['user'];
        print('[LOG]User joined: $user');
        onUserJoined?.call(user);
        break;
      case 'sdp_offer':
        final from = message['from'];
        final sdp = message['sdp'];
        print('[LOG]Received SDP offer from $from');
        onSdpOfferReceived?.call(from, sdp);
        break;
      case 'joined_first':
        _sdpOffer = "DUMMY_SDP_OFFER";
        break;
      default:
        print('[LOG]Unknown message type: ${message['type']}');
    }
  }

  Future<void> _joinRoom() async {
    final joinData = {'type': 'join', 'user_id': _myId, 'room_id': _roomId};
    await sendMessage(joinData);
    print('[LOG]Sent join request: ${jsonEncode(joinData)}');
  }

  Future<void> sendSdpOffer(String to, String sdp) async {
    final message = {
      'type': 'sdp_offer',
      'sdp': sdp,
      'to': to,
      'from': _myId,
    };
    await sendMessage(message);
  }

  Future<void> sendMessage(Map<String, dynamic> data) async {
    if (_socket == null) {
      throw StateError('WebSocket is not connected');
    }
    _socket!.add(jsonEncode(data));
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }
}

// WebRTCService
// プロパティ: 
// メソッド: SDPオファーの作成、SDPアンサーの作成、ICE候補の処理
class WebRTCService {
  Future<
}
