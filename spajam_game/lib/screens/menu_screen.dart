import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/game_state.dart';
import 'lobby_screen.dart';

class MenuScreen extends StatefulWidget {
  static const routeName = '/';
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  final _roomCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  late final AnimationController _anim;          // 背景/飾り用 10s ループ
  late final AnimationController _doorCtrl;      // ふすま開閉用
  double _fusumaOpen = 0.0;                      // 0:閉 1:開
  bool _isTransitioning = false;

  // 追加: キャラ画像リスト（実ファイル名に変更してください）
  static const _characterAssets = [
    'assets/images/normal_cat.png',
    'assets/images/blue_cat.png',
    'assets/images/green_cat.png',
    'assets/images/yellow_cat.png', // 追加
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

    _doorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        setState(() {
          _fusumaOpen = CurvedAnimation(parent: _doorCtrl, curve: Curves.easeInOutCubic).value;
        });
      });
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    _nameCtrl.dispose();
    _anim.dispose();
    _doorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    return Scaffold(
      body: Stack(
        children: [
          // ふすま (左右二枚)
          Positioned.fill(
            child: _FusumaDoors(openProgress: _fusumaOpen),
          ),
          // === キャラクター層 (ふすまの上 / 紙吹雪の下) ===
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => IgnorePointer(
              child: _MenuCharacters(
                t: _anim.value,
                assets: _characterAssets,
              ),
            ),
          ),
          // 紙吹雪(控えめ)
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(_anim.value),
                size: Size.infinite,
              ),
            ),
          ),
          // メインコンテンツ
            Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    const _CatchPhrase(),            // ← 移動: 上部に表示
                    const SizedBox(height: 20),
                    _InputPanel(
                      child: Column(
                        children: [
                          _fieldLabel('ルームID'),
                          _TextFieldWood(
                            controller: _roomCtrl,
                            hint: '例) sp2025',
                            onChanged: state.setRoomId,
                          ),
                          const SizedBox(height: 18),
                          _fieldLabel('ユーザ名'),
                          _TextFieldWood(
                            controller: _nameCtrl,
                            hint: 'あなたの名前',
                            onChanged: state.setUserName,
                          ),
                          const SizedBox(height: 28),
                          _EnterButton(
                            enabled: state.canEnterRoom && !_isTransitioning,
                            animValue: _anim.value,
                            onTap: state.canEnterRoom && !_isTransitioning
                                ? _handleEnterTap
                                : null,
                          ),
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

  Widget _fieldLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF8A5F1F),
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      );

  Future<void> _handleEnterTap() async {
    if (_isTransitioning) return;
    final game = context.read<GameState>();
    setState(() => _isTransitioning = true);

    // 必要ならここでバリデーション再確認
    game.enterRoom();

    await _doorCtrl.forward();          // ふすま開ききる
    if (!mounted) return;
    await Navigator.pushNamed(context, LobbyScreen.routeName);
    if (!mounted) return;

    // 戻ってきたら閉じた状態に戻す
    _doorCtrl.reset();
    setState(() {
      _fusumaOpen = 0.0;
      _isTransitioning = false;
    });
  }
}

/// ============ ふすま Doors ============
class _FusumaDoors extends StatelessWidget {
  final double openProgress; // 0:閉 1:全開 (左右に開く)
  const _FusumaDoors({required this.openProgress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      // 開く距離（中央から左右へ）
      final slide = (w * 0.5) * openProgress;
      // 閉じている時に中央にわずかな隙間 (見せ筋) 6px
      const gap = 6.0;

      return Stack(
        children: [
          // 左扉
          Positioned(
            left: -slide,
            top: 0,
            width: w / 2,
            height: h,
            child: CustomPaint(
              painter: _FusumaPanelPainter(isLeft: true, showHandle: true, gap: gap), // 取っ手表示
            ),
          ),
          // 右扉
          Positioned(
            left: w / 2 + gap - slide * -1, // gap 分ずらす
            top: 0,
            width: w / 2,
            height: h,
            child: CustomPaint(
              painter: _FusumaPanelPainter(isLeft: false, showHandle: true, gap: gap), // 取っ手表示
            ),
          ),
        ],
      );
    });
  }
}

/// 各パネル描画
class _FusumaPanelPainter extends CustomPainter {
  final bool isLeft;
  final bool showHandle;
  final double gap;
  _FusumaPanelPainter({required this.isLeft, required this.showHandle, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    // 外枠(縦の柱)
    final frame = Paint()..color = const Color(0xFF6A4A33);
    final frameW = 14.0;
    // 背面(柱)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), frame);

    // 内側紙
    final paperRect = Rect.fromLTWH(
      isLeft ? frameW : 0,
      0,
      size.width - frameW,
      size.height,
    );
    final paper = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF6EDE1), Color(0xFFE9DBCA)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(paperRect);
    canvas.drawRect(paperRect, paper);

    // 紙の淡い繊維
    final fiber = Paint()..color = const Color(0x22000000);
    final rand = math.Random(isLeft ? 42 : 84);
    for (int i = 0; i < 260; i++) {
      final x = paperRect.left + rand.nextDouble() * paperRect.width;
      final y = rand.nextDouble() * size.height;
      final w = 10 * rand.nextDouble() + 3;
      final h = 1.0;
      final r = Rect.fromCenter(center: Offset(x, y), width: w, height: h);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((rand.nextDouble() - 0.5) * 0.9);
      canvas.translate(-x, -y);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1)), fiber);
      canvas.restore();
    }

    // 中央側縦枠 (合わせ目の厚みを強め)
    final seamColor = const Color(0xFF4F3726);
    final seamW = 10.0;
    final seamRect = Rect.fromLTWH(
      isLeft ? size.width - seamW : 0,
      0,
      seamW,
      size.height,
    );
    canvas.drawRect(seamRect, Paint()..color = seamColor);

    // 引き手 (くぼみ)
    if (showHandle) {
      final handleR = 20.0;
      // シーム(合わせ目)からどれだけ内側へ離すか
      const handleShift = 56.0; // ← 距離調整用。大きくするとさらに中央から離れる

      // 中央側縦枠(seam)の内側基準位置 (以前は seamW * 0.55 付近)
      // isLeft: 右端(中央側)から handleShift 分だけ左へ
      // !isLeft: 左端(中央側)から handleShift 分だけ右へ
      final cx = isLeft
          ? size.width - seamW * 0.55 - handleShift
          : seamW * 0.55 + handleShift;
      final cy = size.height * 0.45;

      final center = Offset(cx, cy);

      // 外縁リング
      final ringPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF5E422C),
            const Color(0xFF3E291B),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: handleR));
      canvas.drawCircle(center, handleR, ringPaint);

      // 内側凹み面
      final innerR = handleR * 0.68;
      final innerPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF3B281C),           // 周囲少し暗い
            const Color(0xFF453226),
            const Color(0xFF4A3528),
            const Color(0xFF2A1B13),           // 中心さらに暗く少し深さ
          ],
          stops: const [0.0, 0.55, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: innerR));
      canvas.drawCircle(center, innerR, innerPaint);

      // 内側ハイライト (上左)
      final highlight = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.35),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: center.translate(-innerR * 0.35, -innerR * 0.35), radius: innerR * 0.9))
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(center, innerR, highlight);

      // 下右のシャドウ (わずかに)
      final shadow = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.black.withOpacity(0.40),
            Colors.black.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: center.translate(innerR * 0.30, innerR * 0.30), radius: innerR * 1.1))
        ..blendMode = BlendMode.multiply;
      canvas.drawCircle(center, innerR, shadow);

      // 内側の薄いエッジ線
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.black.withOpacity(0.45);
      canvas.drawCircle(center, innerR, edge);

      // 上部のエッジハイライト弧
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [
            Color(0x66FFFFFF),
            Color(0x11FFFFFF),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: innerR));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerR * 0.92),
        -140 * math.pi / 180,
        120 * math.pi / 180,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FusumaPanelPainter oldDelegate) =>
      oldDelegate.isLeft != isLeft ||
      oldDelegate.gap != gap ||
      oldDelegate.showHandle != showHandle;
}

/// 中央合わせ目の落ち影
class _CenterSeamShadow extends CustomPainter {
  final double openProgress;
  _CenterSeamShadow({required this.openProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final gap = 6.0 + openProgress * size.width * 0.5;
    // 閉時は細い影、開くほど薄く
    final alpha = (1 - openProgress).clamp(0.0, 1.0);
    final shadowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black.withOpacity(0.18 * alpha),
          Colors.black.withOpacity(0.04 * alpha),
          Colors.black.withOpacity(0.18 * alpha),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(size.width / 2 - gap / 2 - 40, 0, gap + 80, size.height));
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - gap / 2 - 40, 0, gap + 80, size.height),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CenterSeamShadow oldDelegate) =>
      oldDelegate.openProgress != openProgress;
}

/// 入力パネル・木札 / テキストフィールド / ボタンは以前のまま
class _InputPanel extends StatelessWidget {
  final Widget child;
  const _InputPanel({required this.child});
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

class _TextFieldWood extends StatefulWidget {
  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String> onChanged;
  const _TextFieldWood({required this.controller, required this.onChanged, this.hint});

  @override
  State<_TextFieldWood> createState() => _TextFieldWoodState();
}

class _TextFieldWoodState extends State<_TextFieldWood> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        // 背景を濃いブラウンへ (白文字用コントラスト)
        gradient: const LinearGradient(
          colors: [Color(0xFF3D2A1C), Color(0xFF2A1B12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? const Color(0xFFF2D49A) : const Color(0xFFCC9A55),
          width: focused ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (focused)
            BoxShadow(
              color: const Color(0xFFF2D49A).withOpacity(0.35),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      child: TextField(
        focusNode: _focus,
        controller: widget.controller,
        onChanged: widget.onChanged,
        style: const TextStyle(
          color: Colors.white,           // 入力文字を白
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.5,
          height: 1.15,
          shadows: [
            Shadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x66000000)),
          ],
        ),
        cursorColor: const Color(0xFFF2D49A),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
            color: Color(0xCCFFFFFF),    // ヒントはやや薄い白
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _EnterButton extends StatelessWidget {
  final bool enabled;
  final double animValue;
  final VoidCallback? onTap;
  const _EnterButton({required this.enabled, required this.animValue, this.onTap});

  @override
  Widget build(BuildContext context) {
    final beat = enabled ? 1 + 0.05 * math.sin(animValue * math.pi * 2) : 1.0;
    return AnimatedScale(
      scale: beat,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? const [Color(0xFFD94A2C), Color(0xFFB6381D)]
                  : const [Color(0xFFB46E5F), Color(0xFF8E4E3E)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: enabled ? const Color(0xFFF2D49A) : const Color(0xFFD1B78A),
              width: 2,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFFD94A2C).withOpacity(0.55),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            '入　室',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 10,
              color: Colors.white.withOpacity(enabled ? 1 : 0.65),
              shadows: const [
                Shadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x66000000)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 紙吹雪 (控えめ)
class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0x30D94A2C),
      const Color(0x3026435F),
      const Color(0x30D8B25C),
      const Color(0x30B65A30),
    ];
    final paint = Paint();
    const count = 90;
    for (int i = 0; i < count; i++) {
      final seed = (i * 53) % 997;
      final prog = (t + seed / 997) % 1;
      final x = size.width * ((seed * 19) % 100) / 100;
      final y = size.height * prog;
      final w = 4 + (seed % 4);
      paint.color = colors[seed % colors.length];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(prog * 6.283 + seed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w.toDouble(), height: (w * 1.5)),
          const Radius.circular(1.2),
        ),
        paint,
      );
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}

/// キャラクター層
class _MenuCharacters extends StatelessWidget {
  final double t;                 // 0..1 繰り返し
  final List<String> assets;
  const _MenuCharacters({required this.t, required this.assets});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        double floatY(double phase, double amp) =>
            math.sin((t + phase) * math.pi * 2) * amp;

        String? a(int i) => i < assets.length ? assets[i] : null;

        Widget? img(String? path, {double? width, double? height, double opacity = 1}) {
          if (path == null) return null;
          return Opacity(
            opacity: opacity,
            child: Image.asset(
              path,
              width: width,
              height: height,
              fit: BoxFit.contain,
            ),
          );
        }

        final children = <Widget>[];

        // 少し内側へオフセット (画面幅に応じて可変)
        // 修正: clamp(num) → double 取得
        final double edge    = math.min(math.max(w * 0.07, 32.0), 72.0);
        final double topEdge = math.min(math.max(w * 0.09, 36.0), 80.0);
        final bottomLift = 10.0;

        // 共通サイズ
        final charW = w * 0.19;

        // 下 左
        final left = img(a(0), width: charW);
        if (left != null) {
          children.add(Positioned(
            left: edge,
            bottom: bottomLift + floatY(0.05, 6),
            child: left,
          ));
        }

        // 下 右
        final right = img(a(1), width: charW);
        if (right != null) {
          children.add(Positioned(
            right: edge,
            bottom: bottomLift + 6 + floatY(0.33, 6),
            child: right,
          ));
        }

        // 上 左 (green)
        final topLeft = img(a(2), width: charW, opacity: 0.82);
        if (topLeft != null) {
          children.add(Positioned(
            top: topEdge + floatY(0.62, 5),
            left: edge,
            child: topLeft,
          ));
        }

        // 上 右 (yellow)
        final topRight = img(a(3), width: charW, opacity: 0.82);
        if (topRight != null) {
          children.add(Positioned(
            top: topEdge + 6 + floatY(0.78, 5),
            right: edge,
            child: topRight,
          ));
        }

        return Stack(children: children);
      },
    );
  }
}

/// 追加: 上部キャッチコピー用ウィジェット
class _CatchPhrase extends StatelessWidget {
  const _CatchPhrase();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xCC2E1B0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9D4A5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        '3人そろって和音で壁を破れ！',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 4,
          height: 1.2,
          shadows: [
            Shadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x88000000)),
            Shadow(offset: Offset(0, 0), blurRadius: 1.5, color: Color(0x66000000)),
          ],
        ),
      ),
    );
  }
}