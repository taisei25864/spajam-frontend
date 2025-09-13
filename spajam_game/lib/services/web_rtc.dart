import 'dart:convert';
import 'dart:io';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

import 'package:web_socket_channel/web_socket_channel.dart';

class WebRTCVoiceChatService {
  WebRTCVoiceChatService();

  late final RTCPeerConnection peerConnection;
  late final RTCDataChannel dataChannel;
  late final MediaStream localStream;

  Future<void> _connectWebSocket() async {
    final wsUrl = Uri.parse('ws://localhost:8000/ws'); 
    _wsChannel = WebSocketChannel.connect(wsUrl);

    _wsChannel.steam.listen((message) {
      final data = jsonDecode(message);

      if (data['type'] == 'answer') {
        final answer = RTCSessionDescription(data['sdp'], 'answer');
        peerConnection.setRemoteDescription(answer);
      } else if (data['type'] == 'ice-candidate') {
        final candidate = RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        );
        peerConnection.addCandidate(candidate);
      }
    })
  }

  // ICE candidateの送信
  void _sendIceCandidate(RTCIceCandidate candidate) {
    final data = {
      'type': 'ice-candidate',
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    };
    _wsChannel.sink.add(jsonEncode(data));
  }

  // SDPの送信
  void _sendOffer(String sdp) {
    final data = {
      'type': 'offer',
      'sdp': sdp,
    };
    _wsChannel.sink.add(jsonEncode(data));
  }

  Future<void> connect() async {
    // WebRTC用のPeerConnectionを作成
    peerConnection = await createPeerConnection({
      'iceServers': [
        // Googleが提供しているオープンなSTUNサーバを利用
        // https://dev.to/alakkadshaw/google-stun-server-list-21n4
        {'urls': 'stun:stun.l.google.com:19302'},
        // TURNサーバを追加する際は以下に追加（今回は省略）
        // {'urls': 'turn:your-turn-server'},
      ],
    });
    print('Created PeerConnection successfully: $peerConnection');

    // SDPに含めるメディア情報の取得（今回は音声のみ）
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
      'mandatory': {
        'googNoiseSuppression': true,
        'googEchoCancellation': true,
        'googAutoGainControl': true,
        'minSampleRate': 16000,
        'maxSampleRate': 48000,
        'minBitrate': 32000,
        'maxBitrate': 128000,
      },
      'optional': [
        {'googHighpassFilter': true},
      ],
    });

    // PeerConnectionにメディア情報を追加
    localStream.getTracks().forEach((track) {
      peerConnection.addTrack(track, localStream);
    });

    // テキストなどのデータも取得するためデータチャネルを作成
    dataChannel = await peerConnection.createDataChannel(
      'oai-events',
      RTCDataChannelInit(),
    );

    // ICE Candidateが生成された時のコールバック
    // STUNサーバからICE Candidateを受けとるたびに呼ばれる
    peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        _sendIceCandidate(candidate);
      }
    };

    // ICEを通じて接続の状態が変化した時のコールバック
    peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE connection state changed: $state');

      // ICEの手続きが完了したということはWebRTCの接続が確立されたと同義
      if (state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        print('WebRTC connection established successfully!');
      }
    };

    // 音声ストリームを受け取った時のコールバック
    peerConnection.onAddStream = (MediaStream stream) {
      final audioTracks = stream.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        // スピーカーをオンにして読み上げ
        Helper.setSpeakerphoneOn(true);
      }
    };

    // 自分のSDPを作成し、PeerConnectionセット
    final offer = await peerConnection.createOffer();
    if (offer.sdp == null) {
      print('Failed to create offer');
      return;
    }
    await peerConnection.setLocalDescription(offer);
    print('Set local description: ${offer.sdp}');

    // シグナリングサーバを経由して自分のSDP（Offer）をを相手に送信する
    // 同時に相手のSDP（Answer）をレスポンスとして受け取る
    final response =
        await _sendSDPToSignalingServer(sdp: offer.sdp!);
    if (response == null) {
      return;
    }
    final answer = RTCSessionDescription(response, 'answer');

    // 受け取った相手のSDPをPeerConnectionにセット
    await peerConnection.setRemoteDescription(answer);
    print('Set remote description: $answer.sdp');

    // ICEの送受信および経路選択は自動で行われるため、ここでの処理は以上
    // 自分のICEの作成は、setLocalDescriptionを呼んだ後に処理が行われる
    // 相手のICEの受信は、setRemoteDescriptionを呼んだ後に処理が行われる
  }

  // SDPをシグナリングサーバに送信する
  // https://platform.openai.com/docs/guides/realtime-webrtc#connection-details
  Future<String?> _sendSDPToSignalingServer({
    required String sdp,
    required String ephemeralKey,
  }) async {
    final _host = '0.0.0.0'
    final _port = 8000;
    final url = Uri.parse('https://api.openai.com/v1/realtime');
    final client = HttpClient();
    final request = await client.postUrl(url);

    // OpenAIのシグナリングサーバにはEphemeral KeyをAuthorizationヘッダにセットする
    request.headers.set('Authorization', 'Bearer $ephemeralKey');
    request.headers.set('Content-Type', 'application/sdp');
    request.write(sdp);

    final response = await request.close();
    final decodedResponse = await response.transform(utf8.decoder).join();

    if (decodedResponse.isNotEmpty) {
      print('Received SDP(Answer) response: $decodedResponse');
      return decodedResponse;
    } else {
      print('Failed to receive SDP response');
      return null;
    }
  }
}
