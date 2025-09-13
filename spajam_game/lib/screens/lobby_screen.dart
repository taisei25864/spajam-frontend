import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/webrtc_service.dart';
import 'game_screen.dart'; // ルート名利用したい場合

class LobbyScreen extends StatelessWidget {
  static const routeName = '/lobby';
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _LobbyBackground(),
          const _LobbyConfettiLayer(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _LobbyTitle(),
                    const SizedBox(height: 26),
                    _LobbyPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _label('参加メンバー'),
                          const SizedBox(height: 8),
                          _fakeMember('あなた', accent: true),
                          _fakeMember('Player 2'),
                          _fakeMember('Player 3', waiting: true),
                          const SizedBox(height: 22),
                          _label('ステータス'),
                          const SizedBox(height: 8),
                          const _InfoBadge(text: '3人そろい次第スタート', tone: InfoTone.neutral),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD94A2C),
                                foregroundColor: Colors.white,
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: const BorderSide(color: Color(0xFFF2D49A), width: 2),
                                ),
                              ),
                              onPressed: () async {
                                // マイク権限
                                final status = await Permission.microphone.request();
                                if (!status.isGranted) {
                                  debugPrint('Microphone permission denied');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('マイク権限が必要です')),
                                    );
                                  }
                                  return;
                                }

                                final webrtc = context.read<WebRTCService>();
                                if (!webrtc.isConnected) {
                                  try {
                                    await webrtc.init(sendSignal: (json) async {
                                      debugPrint('SEND SIGNAL -> $json');
                                    });
                                    await webrtc.createOffer((json) async {
                                      debugPrint('SEND SIGNAL -> $json');
                                    });
                                  } catch (e) {
                                    debugPrint('WebRTC init error: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('音声初期化に失敗しました')),
                                      );
                                    }
                                    return;
                                  }
                                }
                                if (context.mounted) {
                                  Navigator.pushNamed(context, GameScreen.routeName);
                                }
                              },
                              child: const Text(
                                'スタート',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 8,
                                  shadows: [
                                    Shadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x66000000)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fakeMember(String name, {bool accent = false, bool waiting = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent
            ? const Color(0xFF3D2A1C)
            : const Color(0xFF3D2A1C).withOpacity(0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent ? const Color(0xFFF2D49A) : const Color(0xFF9E7B52),
          width: accent ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            waiting ? Icons.hourglass_top : Icons.person,
            size: 20,
            color: waiting ? const Color(0xFFE9C780) : const Color(0xFFF8E3B4),
          ),
          const SizedBox(width: 10),
            Expanded(
              child: Text(
                waiting ? '$name (待機)' : name,
                style: TextStyle(
                  color: Colors.white.withOpacity(waiting ? 0.75 : 0.95),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  shadows: const [
                    Shadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x88000000)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF8A5F1F),
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            fontSize: 13,
          ),
        ),
      );
}

class _LobbyTitle extends StatelessWidget {
  const _LobbyTitle();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xCC2E1B0E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D4A5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.38),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Text(
        'ロビー',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 8,
          shadows: [
            Shadow(offset: Offset(0, 3), blurRadius: 6, color: Color(0x88000000)),
          ],
        ),
      ),
    );
  }
}

class _LobbyPanel extends StatelessWidget {
  final Widget child;
  const _LobbyPanel({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E9DA).withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD3B48A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: child,
    );
  }
}

enum InfoTone { neutral, alert, ok }

class _InfoBadge extends StatelessWidget {
  final String text;
  final InfoTone tone;
  const _InfoBadge({required this.text, required this.tone});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    switch (tone) {
      case InfoTone.alert:
        bg = const Color(0xFFD94A2C);
        border = const Color(0xFFF2D49A);
        break;
      case InfoTone.ok:
        bg = const Color(0xFF2E7040);
        border = const Color(0xFFB8DBAC);
        break;
      default:
        bg = const Color(0xFF3D2A1C);
        border = const Color(0xFF9E7B52);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          shadows: [
            Shadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x88000000)),
          ],
        ),
      ),
    );
  }
}

class _LobbyBackground extends StatelessWidget {
  const _LobbyBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6EDE1), Color(0xFFE9DBCA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _LobbyConfettiLayer extends StatefulWidget {
  const _LobbyConfettiLayer();
  @override
  State<_LobbyConfettiLayer> createState() => _LobbyConfettiLayerState();
}

class _LobbyConfettiLayerState extends State<_LobbyConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => IgnorePointer(
        child: CustomPaint(
          painter: _LobbyConfettiPainter(_c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _LobbyConfettiPainter extends CustomPainter {
  final double t;
  _LobbyConfettiPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0x22D94A2C),
      const Color(0x2226435F),
      const Color(0x22D8B25C),
      const Color(0x22B65A30),
    ];
    final paint = Paint();
    const count = 50;
    for (int i = 0; i < count; i++) {
      final seed = (i * 37) % 997;
      final prog = (t + seed / 997) % 1;
      final x = size.width * ((seed * 23) % 100) / 100;
      final y = size.height * prog;
      final w = 3 + (seed % 3);
      paint.color = colors[seed % colors.length];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(prog * 6.283 + seed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w.toDouble(), height: w * 1.4),
          const Radius.circular(1.2),
        ),
        paint,
      );
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant _LobbyConfettiPainter old) => old.t != t;
}