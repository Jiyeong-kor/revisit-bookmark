# Revisit Bookmark

> 저장만 하고 다시 보지 않는 링크와 메모를, 홈 화면 위젯이 매일 다시 꺼내 보여줍니다.

[![Flutter](https://img.shields.io/badge/Flutter-3.41.9-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.5-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 문제

사람들은 X 북마크, Instagram 저장, 스크린샷, 메모장에 유용한 정보를 저장합니다.  
하지만 **나중에 다시 열어보는 경우는 극히 드뭅니다.**

저장된 정보는 앱 깊숙이 묻혀 사라지고, 금방 잊혀집니다.

## 해결

저장한 **링크·스크린샷·메모**를 홈 화면 위젯에서 **랜덤으로 다시 보여줍니다.**  
앱을 열지 않아도, 매일 잊고 있던 콘텐츠를 자연스럽게 재발견하게 만듭니다.

## 결과 (목표)

- 저장한 콘텐츠를 다시 발견하는 경험 제공
- 홈 화면만으로 완결되는 미니멀한 UX
- Google Play 출시 예정 (v1.0)

---

## 주요 기능

| 기능 | 상태 |
|---|---|
| 링크 직접 저장 + Open Graph 썸네일 자동 추출 | 🔜 개발 예정 |
| 스크린샷 저장 (Android Photo Picker) | 🔜 개발 예정 |
| 메모 직접 입력 / 공유 인텐트로 저장 | 🔜 개발 예정 |
| 홈 화면 위젯 (랜덤 콘텐츠 표시) | 🔜 개발 예정 |
| 태그 · 카테고리 분류 | 🔜 개발 예정 |

---

## 기술 스택

- **Framework**: Flutter 3.41.9 / Dart 3.11.5
- **Platform**: Android (iOS 확장 가능 구조 유지)
- **홈 화면 위젯**: Android App Widget API (Glance)
- **로컬 저장소**: 검토 중 (Hive / Drift)
- **OG 썸네일**: Open Graph Protocol 파싱
- **이미지 선택**: Android Photo Picker (권한 최소화)

---

## 아키텍처

```
lib/
├── core/           # 공통 유틸리티, 상수, 에러 처리
├── data/           # 데이터 레이어 (모델, 로컬 DB, 외부 API)
│   ├── models/
│   ├── repositories/
│   └── datasources/
├── domain/         # 비즈니스 로직 (UseCase, Repository 인터페이스)
├── presentation/   # UI 레이어 (페이지, 위젯, 상태 관리)
│   ├── pages/
│   └── widgets/
└── main.dart
```

> Feature-based clean architecture 적용 예정

---

## 시작하기

### 요구사항

- Flutter SDK 3.41.9 이상
- Android Studio / VS Code
- Android SDK (API 26+)

### 설치 및 실행

```bash
# 저장소 클론
git clone https://github.com/[your-username]/revisit-bookmark.git
cd revisit-bookmark

# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

### 빌드

```bash
# 정적 분석
flutter analyze

# 테스트
flutter test

# 릴리스 빌드 (APK)
flutter build apk --release

# 릴리스 빌드 (App Bundle)
flutter build appbundle --release
```

---

## 개발 현황

현재 프로젝트 초기 설정 단계입니다. 진행 상황은 [GitHub Issues](../../issues)와 [Projects](../../projects)에서 확인할 수 있습니다.

---

## 로드맵

### v1.0 (첫 출시)
- [ ] 프로젝트 아키텍처 설계
- [ ] 링크 저장 + OG 썸네일 추출
- [ ] 스크린샷 저장 (Photo Picker)
- [ ] 메모 저장 + 공유 인텐트
- [ ] 홈 화면 위젯 (랜덤 표시)
- [ ] Google Play 스토어 출시

### v1.x (이후)
- [ ] 잠금화면 위젯
- [ ] 태그 · 카테고리
- [ ] iOS 지원

---

## 기여하기

[CONTRIBUTING.md](CONTRIBUTING.md) 를 참고해 주세요.  
버그 제보 및 기능 제안은 [Issues](../../issues)를 이용해 주세요.

---

## 라이선스

[MIT License](LICENSE)
