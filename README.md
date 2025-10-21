# 🎯 Random Picker - 랜덤 선택 앱

점심 커피 내기, 발표자 선정 등 공정한 랜덤 선택이 필요할 때 사용하는 재미있는 Flutter 앱입니다!

## ✨ 주요 기능

- 🖐️ **멀티터치 지원**: iOS에서 최대 11개의 손가락을 동시에 인식 (기기에 따라 다를 수 있음)
- 🎨 **화려한 비주얼**: 각 터치마다 다른 색상의 화려한 원으로 표현
- ⏱️ **자동 감지**: 2초 동안 추가 터치가 없으면 자동으로 선택 시작
- 🎭 **긴장감 연출**: 3초 카운트다운으로 긴장감 극대화
- 👑 **당첨자 표시**: 선택된 손가락에 왕관과 특별 효과 표시
- 🔄 **간편한 재시작**: 언제든 다시 하기 버튼으로 새로운 라운드 시작

## 🎮 사용 방법

1. 앱을 실행합니다
2. 참가자들이 화면에 손가락을 올립니다
3. 모든 참가자가 터치한 후 2초 동안 기다립니다
4. 3-2-1 카운트다운이 시작됩니다
5. 랜덤으로 한 명이 선택됩니다!
6. 당첨자 확인 후 "다시 하기" 버튼으로 재시작

## 🛠️ 개발 환경 설정

### 필요 사항
- Flutter SDK (3.0 이상 권장)
- Xcode (iOS 개발용)
- macOS (iOS 앱 빌드를 위해 필요)

### 설치 및 실행

```bash
# 저장소 클론 (또는 프로젝트 폴더로 이동)
cd randompicker

# 의존성 설치
flutter pub get

# iOS 시뮬레이터 실행
open -a Simulator

# 앱 실행
flutter run
```

### 실제 iOS 기기에서 실행

```bash
# 연결된 기기 확인
flutter devices

# 특정 기기에서 실행
flutter run -d [device-id]
```

**주의**: 실제 기기에서 멀티터치 테스트를 하려면 물리적 iOS 기기가 필요합니다. 시뮬레이터는 멀티터치를 완전히 지원하지 않습니다.

## 📱 iOS 멀티터치 설정

iOS에서 멀티터치를 지원하기 위해 `ios/Runner/Info.plist`에 다음 설정이 추가되어 있습니다:

```xml
<key>UIMultipleSimultaneousTouch</key>
<true/>
```

이 설정으로 iOS에서 최대 11개의 동시 터치를 인식할 수 있습니다 (기기에 따라 다를 수 있음).

## 🎨 기술적 특징

### 1. 멀티터치 처리
- `Listener` 위젯을 사용하여 로우레벨 포인터 이벤트 처리
- `PointerDownEvent`, `PointerMoveEvent`, `PointerUpEvent` 활용
- 각 터치 포인트에 고유 ID와 색상 할당

### 2. 화려한 애니메이션
- **펄스 애니메이션**: 터치 포인트가 살짝 커졌다 작아지는 호흡 효과
- **선택 애니메이션**: 당첨자 선택 시 탄성 있는 확대 효과
- **그라디언트 & 글로우**: 각 원에 방사형 그라디언트와 외곽 글로우 적용

### 3. CustomPainter 활용
- `CustomPaint`와 `CustomPainter`로 고성능 그래픽 렌더링
- `Canvas` API를 사용한 원, 그라디언트, 블러 효과 구현
- 애니메이션과 연동하여 부드러운 시각 효과

### 4. 상태 관리
- 터치 포인트 맵으로 여러 터치 동시 관리
- Timer를 활용한 자동 카운트다운 로직
- 선택 프로세스 중 추가 입력 차단

## 🎨 색상 팔레트

앱은 15가지 화려한 색상 팔레트를 사용합니다:
- 빨강 (#FF6B6B)
- 청록 (#4ECDC4)
- 노랑 (#FFE66D)
- 민트 (#95E1D3)
- 핑크 (#F38181)
- 보라 (#AA96DA)
- 주황 (#FFCACA)
- 하늘 (#48CFCB)
- 연분홍 (#FF85A2)
- 연두 (#90EE90)
- 라이트 핑크 (#FFB6C1)
- 스카이 블루 (#87CEEB)
- 자두 (#DDA0DD)
- 카키 (#F0E68C)
- 피치 (#FFDAB9)

## 📐 프로젝트 구조

```
randompicker/
├── lib/
│   └── main.dart              # 메인 앱 코드
├── ios/
│   └── Runner/
│       └── Info.plist         # iOS 설정 (멀티터치 포함)
├── android/                   # Android 설정
├── pubspec.yaml              # 프로젝트 의존성
└── README.md                 # 이 파일
```

## 🔧 커스터마이징 가이드

### 타이밍 조정
```dart
// 추가 터치 대기 시간 (기본: 2초)
_countdownTimer = Timer(const Duration(seconds: 2), () { ... });

// 긴장감 카운트다운 시간 (기본: 3초)
for (int i = 3; i > 0; i--) { ... }

// 결과 표시 시간 (기본: 5초)
await Future.delayed(const Duration(seconds: 5));
```

### 터치 포인트 크기 조정
```dart
TouchPoint({
  // ...
  this.size = 60.0,  // 기본 크기를 변경
});
```

### 색상 팔레트 수정
```dart
final List<Color> _colorPalette = [
  Color(0xFFYOURCOLOR),  // 원하는 색상 추가
  // ...
];
```

### 애니메이션 속도 조정
```dart
// 펄스 애니메이션 속도
_pulseController = AnimationController(
  duration: const Duration(milliseconds: 1000),  // 변경
  vsync: this,
);

// 선택 애니메이션 속도
_selectionController = AnimationController(
  duration: const Duration(milliseconds: 800),  // 변경
  vsync: this,
);
```

## 🐛 트러블슈팅

### 멀티터치가 작동하지 않을 때
1. 실제 iOS 기기에서 테스트하고 있는지 확인 (시뮬레이터는 제한적)
2. `Info.plist`에 `UIMultipleSimultaneousTouch` 설정이 있는지 확인
3. 앱을 완전히 종료하고 재시작

### 앱이 느릴 때
1. Release 모드로 빌드: `flutter run --release`
2. 색상 팔레트 크기 줄이기
3. 애니메이션 duration 늘리기

### 빌드 에러 발생 시
```bash
# 캐시 클리어
flutter clean

# 의존성 재설치
flutter pub get

# iOS 포드 재설치
cd ios
pod install
cd ..

# 재빌드
flutter run
```

## 🎯 사용 시나리오

- ☕ **점심 커피/식사 내기**: 누가 커피를 사올지 공정하게 선택
- 🎤 **발표자 선정**: 수업이나 회의에서 발표자 랜덤 선택
- 🎮 **게임 순서 정하기**: 게임 시작 순서나 팀 정하기
- 🍕 **숙제/심부름 담당자**: 집안일 담당자 공정하게 선택
- 🎉 **이벤트 당첨자**: 간단한 경품 추첨이나 이벤트

## 📄 라이선스

이 프로젝트는 개인 및 상업적 용도로 자유롭게 사용 가능합니다.

## 🤝 기여

버그 리포트나 기능 제안은 언제든 환영합니다!

## 👨‍💻 개발자

Flutter로 만든 즐거운 랜덤 선택 앱 🎉

---

**즐거운 랜덤 선택 되세요! 🎲**

