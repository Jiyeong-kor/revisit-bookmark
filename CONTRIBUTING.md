# 기여 가이드

## 브랜치 전략

```
main          ← 릴리스 태그 전용 (직접 커밋 금지)
develop       ← 통합 브랜치 (모든 feat/fix는 여기로 PR)
feat/xxx      ← 기능 개발
fix/xxx       ← 버그 수정
chore/xxx     ← 설정·인프라
release/x.x.x ← 릴리스 준비
```

## 커밋 메시지 규칙

[Conventional Commits](https://www.conventionalcommits.org/) 규칙을 따릅니다.

```
<type>: <subject>

type 목록:
  feat     - 새 기능
  fix      - 버그 수정
  refactor - 리팩토링 (기능 변경 없음)
  test     - 테스트 추가/수정
  chore    - 빌드, 설정, 의존성
  docs     - 문서
  style    - 포맷팅 (기능 변경 없음)
  perf     - 성능 개선
```

예시:
```
feat: 링크 저장 시 OG 썸네일 자동 추출
fix: 홈 위젯에서 메모 텍스트 잘림 현상 수정
chore: flutter_lints 버전 업데이트
```

## PR 규칙

1. `develop` 브랜치를 기준으로 feature 브랜치를 생성합니다.
2. PR은 `develop`으로 올립니다.
3. PR 제목도 Conventional Commits 형식을 따릅니다.
4. `flutter analyze`와 `flutter test`가 통과해야 합니다.

## 로컬 개발 환경 설정

```bash
# 저장소 클론
git clone https://github.com/[username]/revisit-bookmark.git
cd revisit-bookmark

# develop 브랜치로 이동
git checkout develop

# 의존성 설치
flutter pub get

# 분석 실행
flutter analyze

# 테스트 실행
flutter test
```
