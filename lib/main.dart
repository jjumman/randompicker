import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Picker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const RandomPickerScreen(),
    );
  }
}

class TouchPoint {
  final int id;
  final Offset position;
  final Color color;
  final double size;

  TouchPoint({
    required this.id,
    required this.position,
    required this.color,
    this.size = 60.0,
  });
}

class RandomPickerScreen extends StatefulWidget {
  const RandomPickerScreen({super.key});

  @override
  State<RandomPickerScreen> createState() => _RandomPickerScreenState();
}

class _RandomPickerScreenState extends State<RandomPickerScreen>
    with TickerProviderStateMixin {
  final Map<int, TouchPoint> _activeTouches = {};
  final List<Color> _usedColors = [];
  Timer? _countdownTimer;
  int? _selectedTouchId;
  bool _isSelecting = false;
  bool _isRotating = false; // 회전 중인지 구분
  int _countdown = 1;
  final Random _random = Random();
  int _currentRotationIndex = 0;
  Timer? _rotationTimer;
  Timer? _autoResetTimer; // 자동 리셋 타이머

  // 화려한 색상 팔레트 (충분히 많은 색상)
  final List<Color> _colorPalette = [
    Color(0xFFFF6B6B), // 빨강
    Color(0xFF4ECDC4), // 청록
    Color(0xFFFFE66D), // 노랑
    Color(0xFF95E1D3), // 민트
    Color(0xFFF38181), // 핑크
    Color(0xFFAA96DA), // 보라
    Color(0xFFFCACA), // 주황
    Color(0xFF48CFCB), // 하늘
    Color(0xFFFF85A2), // 연분홍
    Color(0xFF90EE90), // 연두
    Color(0xFFFFB6C1), // 라이트 핑크
    Color(0xFF87CEEB), // 스카이 블루
    Color(0xFFDDA0DD), // 자두
    Color(0xFFF0E68C), // 카키
    Color(0xFFFFDAB9), // 피치
  ];

  late AnimationController _pulseController;
  late AnimationController _selectionController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 펄스 애니메이션 (터치 포인트가 살짝 커졌다 작아지는 효과)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 선택 애니메이션
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _rotationTimer?.cancel();
    _autoResetTimer?.cancel();
    _pulseController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  Color _getUniqueColor() {
    // 사용하지 않은 색상 중에서 선택
    final availableColors = _colorPalette
        .where((color) => !_usedColors.contains(color))
        .toList();

    if (availableColors.isEmpty) {
      // 모든 색상을 사용했으면 리셋하고 다시 선택
      _usedColors.clear();
      return _colorPalette[_random.nextInt(_colorPalette.length)];
    }

    final selectedColor = availableColors[_random.nextInt(availableColors.length)];
    _usedColors.add(selectedColor);
    return selectedColor;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_isRotating) return; // 회전 중에는 새로운 터치 불가

    setState(() {
      _activeTouches[event.pointer] = TouchPoint(
        id: event.pointer,
        position: event.localPosition,
        color: _getUniqueColor(),
      );
      _selectedTouchId = null;
    });

    _resetCountdown();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    // 회전 중에도 계속 손가락 따라다니기!
    if (_activeTouches.containsKey(event.pointer)) {
      setState(() {
        _activeTouches[event.pointer] = TouchPoint(
          id: event.pointer,
          position: event.localPosition,
          color: _activeTouches[event.pointer]!.color,
        );
      });
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    // 선택이 진행 중이면 터치 제거를 무시 (회전 방해 방지)
    if (_isSelecting) {
      // 원은 유지하되 더 이상 추적하지 않음
      return;
    }

    final removedTouch = _activeTouches[event.pointer];
    setState(() {
      _activeTouches.remove(event.pointer);
    });

    // 제거된 터치의 색상을 재사용 가능하도록
    if (removedTouch != null) {
      _usedColors.remove(removedTouch.color);
    }

    if (_activeTouches.isEmpty) {
      _countdownTimer?.cancel();
      setState(() {
        _countdown = 1;
      });
    } else {
      _resetCountdown();
    }
  }

  void _resetCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdown = 1;
    });

    _countdownTimer = Timer(const Duration(seconds: 1), () {
      if (_activeTouches.isNotEmpty) {
        _startSelection();
      }
    });
  }

  void _startSelection() async {
    if (_activeTouches.isEmpty || _isSelecting) return;

    // 이전 자동 리셋 타이머 취소
    _autoResetTimer?.cancel();

    setState(() {
      _isSelecting = true;
      _isRotating = true; // 바로 회전 시작
      _currentRotationIndex = 0;
      _countdown = 0; // 카운트다운 숫자 숨김
    });

    // 룰렛 회전 효과 (1.5초)
    await _startRouletteRotation();

    // 리셋되었는지 확인
    if (!_isSelecting) return;

    _selectionController.forward(from: 0.0);

    // 5초 후 자동 리셋 (타이머 사용)
    _autoResetTimer = Timer(const Duration(seconds: 5), () {
      if (_isSelecting) {
        _reset();
      }
    });
  }

  Future<void> _startRouletteRotation() async {
    final keys = _activeTouches.keys.toList();
    if (keys.isEmpty) return;

    // 빠른 회전 (약 1.5초)
    int rotationCount = 0;
    int maxRotations = 20 + _random.nextInt(8); // 20~27회 회전
    int baseDelay = 25; // 기본 딜레이 (밀리초) - 빠르게 시작

    _rotationTimer?.cancel();

    while (rotationCount < maxRotations) {
      // 리셋되었는지 확인
      if (!_isSelecting || !mounted) return;

      // 점점 느려지는 효과
      double speedMultiplier = 1.0 + (rotationCount / maxRotations) * 4;
      int currentDelay = (baseDelay * speedMultiplier).round();

      setState(() {
        _currentRotationIndex = rotationCount % keys.length;
      });

      // 모든 회전마다 진동
      HapticFeedback.lightImpact();

      await Future.delayed(Duration(milliseconds: currentDelay));
      rotationCount++;
    }

    // 리셋되었는지 확인
    if (!_isSelecting || !mounted) return;

    // 마지막 선택
    final selectedIndex = _random.nextInt(keys.length);
    setState(() {
      _currentRotationIndex = selectedIndex;
      _selectedTouchId = keys[selectedIndex];
    });

    // 당첨 진동 (더 강하게)
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!_isSelecting || !mounted) return;
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!_isSelecting || !mounted) return;
    HapticFeedback.heavyImpact();
  }

  void _reset() {
    // 모든 타이머 취소
    _countdownTimer?.cancel();
    _rotationTimer?.cancel();
    _autoResetTimer?.cancel();

    setState(() {
      _activeTouches.clear();
      _usedColors.clear();
      _selectedTouchId = null;
      _isSelecting = false;
      _isRotating = false;
      _countdown = 1;
      _currentRotationIndex = 0;
    });

    _selectionController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF64B5F6), // 밝은 파란색 배경
      body: SafeArea(
        child: Stack(
          children: [
            // 터치 영역
            Listener(
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Color(0xFF64B5F6), // 밝은 파란색
                child: CustomPaint(
                  painter: TouchPointPainter(
                    touches: _activeTouches.values.toList(),
                    selectedTouchId: _selectedTouchId,
                    pulseAnimation: _pulseAnimation,
                    scaleAnimation: _scaleAnimation,
                    isSelecting: _isSelecting,
                    currentRotationIndex: _currentRotationIndex,
                  ),
                ),
              ),
            ),

            // 상단 상태 표시
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Random Picker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black26,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_activeTouches.isEmpty && !_isSelecting)
                    Text(
                      '화면을 터치하세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            blurRadius: 5.0,
                            color: Colors.black26,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    )
                  else if (_countdown > 0 && !_isSelecting)
                    Text(
                      '${_activeTouches.length}명 참여 중... (${_countdown}초)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            blurRadius: 5.0,
                            color: Colors.black26,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    )
                  else if (_isSelecting && _countdown == 0 && _selectedTouchId == null)
                    Text(
                      '선택 중...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black38,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    )
                  else if (_selectedTouchId != null)
                    Column(
                      children: [
                        const Text(
                          '🎉 당첨! 🎉',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black38,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_activeTouches.length}명 중 선택됨',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                blurRadius: 5.0,
                                color: Colors.black26,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else if (_isSelecting && _countdown == 0)
                    Text(
                      '선택 중...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black38,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 리셋 버튼
            if (_selectedTouchId != null || _isSelecting)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton(
                    onPressed: _reset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      '다시 하기',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // 참여자 수 표시
            if (_activeTouches.isNotEmpty && !_isSelecting)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '참여자: ${_activeTouches.length}명',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TouchPointPainter extends CustomPainter {
  final List<TouchPoint> touches;
  final int? selectedTouchId;
  final Animation<double> pulseAnimation;
  final Animation<double> scaleAnimation;
  final bool isSelecting;
  final int currentRotationIndex;

  TouchPointPainter({
    required this.touches,
    required this.selectedTouchId,
    required this.pulseAnimation,
    required this.scaleAnimation,
    required this.isSelecting,
    required this.currentRotationIndex,
  }) : super(repaint: Listenable.merge([pulseAnimation, scaleAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < touches.length; i++) {
      final touch = touches[i];
      final isSelected = touch.id == selectedTouchId;
      final isRotating = isSelecting && !isSelected && i == currentRotationIndex;

      // 선택된 것은 크게, 회전 중인 것은 중간, 나머지는 보통
      final scale = isSelected
          ? scaleAnimation.value
          : (isRotating ? 1.3 : pulseAnimation.value);
      final baseSize = touch.size * scale;

      // 회전 중인 터치는 더 밝게 표시
      final opacity = isRotating ? 1.0 : (isSelected ? 1.0 : 0.85);

      // 외곽 글로우 효과
      final glowPaint = Paint()
        ..color = touch.color.withOpacity(0.4 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
      canvas.drawCircle(touch.position, baseSize * 1.6, glowPaint);

      // 메인 원 (그라디언트)
      final rect = Rect.fromCircle(
        center: touch.position,
        radius: baseSize,
      );

      final gradient = RadialGradient(
        colors: [
          touch.color.withOpacity(0.95 * opacity),
          touch.color.withOpacity(0.7 * opacity),
          touch.color.withOpacity(0.4 * opacity),
        ],
        stops: const [0.0, 0.7, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(touch.position, baseSize, paint);

      // 선택된 터치에 추가 효과
      if (isSelected) {
        // 왕관 이모지
        final textPainter = TextPainter(
          text: const TextSpan(
            text: '👑',
            style: TextStyle(fontSize: 50),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            touch.position.dx - textPainter.width / 2,
            touch.position.dy - baseSize - 60,
          ),
        );

        // 반짝이는 링 (금색 대신 밝은 청록색)
        final ringPaint = Paint()
          ..color = Color(0xFF00E5FF) // 밝은 시안 색상
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5;
        canvas.drawCircle(touch.position, baseSize + 20, ringPaint);

        // 추가 외곽 링 (보라색)
        final outerRingPaint = Paint()
          ..color = Color(0xFFE040FB) // 밝은 보라색
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(touch.position, baseSize + 30, outerRingPaint);
      }

      // 회전 중인 터치 표시
      if (isRotating) {
        final rotatingRingPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawCircle(touch.position, baseSize + 15, rotatingRingPaint);
      }

      // 테두리
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(isSelected || isRotating ? 1.0 : 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 5 : (isRotating ? 4 : 2);
      canvas.drawCircle(touch.position, baseSize, borderPaint);

      // 중앙 하이라이트
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.7 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(
        Offset(touch.position.dx - baseSize * 0.3, touch.position.dy - baseSize * 0.3),
        baseSize * 0.35,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TouchPointPainter oldDelegate) {
    return oldDelegate.touches != touches ||
        oldDelegate.selectedTouchId != selectedTouchId ||
        oldDelegate.isSelecting != isSelecting ||
        oldDelegate.currentRotationIndex != currentRotationIndex;
  }
}
