import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// シグナリング(例: WebSocket)は後で注入する想定
class WebRTCService with ChangeNotifier {
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  bool get isConnected => _pc != null;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  Future<void> init({required Future<void> Function(String json) sendSignal}) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };
    _pc = await createPeerConnection(config);

    _pc!.onIceCandidate = (c) {
      if (c.candidate != null) {
        sendSignal(jsonEncode({
          'type': 'candidate',
          'candidate': c.toMap(),
        }));
      }
    };

    _remoteStream = await createLocalMediaStream('remote');
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        notifyListeners();
      }
    };

    await _setupLocalAudioTrack();
  }

  Future<void> _setupLocalAudioTrack() async {
    final constraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    for (var track in _localStream!.getAudioTracks()) {
      await _pc?.addTrack(track, _localStream!);
    }
    notifyListeners();
  }

  Future<void> createOffer(Future<void> Function(String json) sendSignal) async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    await sendSignal(jsonEncode({'type': 'offer', 'sdp': offer.sdp}));
  }

  Future<void> handleSignal(String data, Future<void> Function(String json) sendSignal) async {
    final map = jsonDecode(data);
    switch (map['type']) {
      case 'offer':
        final desc = RTCSessionDescription(map['sdp'], 'offer');
        await _pc!.setRemoteDescription(desc);
        final answer = await _pc!.createAnswer();
        await _pc!.setLocalDescription(answer);
        await sendSignal(jsonEncode({'type': 'answer', 'sdp': answer.sdp}));
        break;
      case 'answer':
        final desc = RTCSessionDescription(map['sdp'], 'answer');
        await _pc!.setRemoteDescription(desc);
        break;
      case 'candidate':
        final cand = map['candidate'];
        final ice = RTCIceCandidate(
          cand['candidate'],
          cand['sdpMid'],
            cand['sdpMLineIndex'],
        );
        await _pc!.addCandidate(ice);
        break;
    }
  }

  Future<void> disposeConnection() async {
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _pc?.close();
    _localStream = null;
    _remoteStream = null;
    _pc = null;
    notifyListeners();
  }
}